# Copyright (c) 2006, 2007 Ruffdogs Software, Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

require 'drb'
require 'digest/md5'
require 'thread'
require 'singleton'
require 'backgroundrb/thread_pool'
require 'backgroundrb/worker'
require 'backgroundrb/scheduler'
require 'backgroundrb/trigger'
require 'backgroundrb/cron_trigger'
require 'backgroundrb/results'
require 'slave'
require 'yaml'


class BackgrounDRbDuplicateKeyError < ArgumentError; end
class BackgrounDRbUnknownTriggerType < ArgumentError; end
class BackgrounDRbWorkerClassNotRegistered < ArgumentError; end

module BackgrounDRb

  #http://onestepback.org/index.cgi/Tech/Ruby/BuilderObjects.rdoc
  class BlankSlate # :nodoc:
    instance_methods.each { |m| undef_method m unless m =~ /^__/ }
  end

  # The WorkerProxy is used to make the DRb connection go from the
  # MiddleMan to the slave process. It allows us to catch exception on
  # the server side without the client (which get the MiddleMan
  # DRbObject) having to deal the cases where a slave/worker goes away.
  # This is also where we provide a uniform access to worker results,
  # even after the worker is terminated. From a results standpoint,
  # named workers become singletons.
  class WorkerProxy < BlankSlate
    include DRbUndumped
    include BackgrounDRb::Worker
    include BackgrounDRb::Results

    def initialize(worker)
      @worker = worker
      @jobkey = worker.jobkey
    end

    # this one is snagged from DRb::DRbObject#respond_to?
    def respond_to?(msg_id, priv=false)
      case msg_id
      when :_dump
        true
      when :marshal_dump
        false
      else
        method_missing(:respond_to?, msg_id, priv)
      end
    end

    def method_missing(sym, *args, &block)
      case sym 
      when :delete, :results
        begin
          @worker.__send__(sym, *args, &block)
        rescue DRb::DRbConnError => e
          # This will return the results for the worker even after it
          # has terminated.
          if sym == :results
            results = {}
            results.extend(BackgrounDRb::Results)
            results.init(@jobkey)
            results
          end

        end
      else
        #puts "Sending #{sym}(#{args.join(',')}) to obj"
        @worker.__send__(sym, *args, &block)
      end
    end
  end

  class MiddleMan
    include DRbUndumped
    include Singleton

    attr_accessor :scheduler
    attr_reader :worker_classes
    
    def setup(opts={})
      @jobs = Hash.new
      @in_setup = Hash.new
      @mutex = Mutex.new
      @timestamps = Hash.new
      @thread_pool = ThreadPool.new(opts[:pool_size] || 30)
      @scheduler = opts[:scheduler]
      

      self.load_worker_classes
      new_worker(:class => :'LoggerWorker', :job_key => :restore_logger, :args => {'logfile' => opts[:logfile]})
      new_worker(:class => :'ResultsWorker', :job_key => :restore_results)
      new_worker(:class => :'StorageWorker', :job_key => :restore_storage)
      
      
      self.scheduler.run

      self.load_worker_schedules

      self
    end  

    def load_worker_schedules
      new_worker(:class => 'ScheduleWorker', :job_key => :schedule)
    end


    def load_worker_classes
      Dir["#{RESTORE_BACKEND_ROOT}/workers/*.rb"].each do |worker| 
        begin
          BackgrounDRb::ServerLogger.logger.info('middleman') do 
            "Loading Worker Class File: #{worker}"
          end
          load worker 
        rescue Exception => e
          BackgrounDRb::ServerLogger.logger.info('middleman') do 
            "Failed to load: #{worker}"
          end
          BackgrounDRb::ServerLogger.log_exception('middleman', e) 
        end
      end


    end

    # mimic rails console reload!
    alias :reload! :load_worker_classes

  
    def new_worker(opts={})

      is_gen_key = false
      job_key = opts[:job_key] || lambda { is_gen_key = true; gen_key }.call

      w_klass = opts[:class]
      w_args = opts[:args]

      worker_klass = worker_klass_constant(w_klass)

      if not jobs[job_key] 
        m = self

        # Use in_setup to keep track of job_keys not in jobs[yet]. Avoid
        # a jobs[job_key] race where a second call to new_worker with
        # the same job_key could result in a second dispatch.
        unless in_setup?(job_key)

          @thread_pool.dispatch do

            # Set ps name for the slave process
            case job_key
            when :restore_logger, :restore_results, :restore_storage
              psname = job_key.to_s
            else
              psname = "restore_#{job_key}".gsub('::', '_').downcase
            end

            begin
              #require 'drb/timeridconv'
              #DRb.install_id_conv DRb::TimerIdConv.new
              
              slave_obj = Slave.new({ :psname => psname,
                                    :threadsafe => true,
                  :object => worker_klass.new(w_args, job_key)}) do |s|
              end
            rescue => e
              BackgrounDRb::ServerLogger.log_exception('middleman', e) 
            end

            slave_obj.wait(:non_block=>true) do 
              self.delete_worker(job_key)
            end

            #ObjectSpace.define_finalizer(slave_obj){ 
            #  self.delete_worker job_key 
            #}

            BackgrounDRb::ServerLogger.logger.info('middleman') { 
              "Starting worker: #{w_klass} #{job_key} (#{psname})"
            }

            # add Slave#delete to allow self destruct
            class << slave_obj
              def delete
                MiddleMan.instance.delete_worker(self.obj.jobkey)
              end
            end

            # we can't call this inside the Server.new block since #delete
            # and @process is not set up.
            slave_obj.object.work_thread(:method => :do_work, :args => :@args)

            m[job_key] = slave_obj
          end.join
          out_of_setup(job_key)
        else
          # If we get here, it means that a worker with the given
          # job_key is already dispatched. We'll wait around until it is
          # available in jobs[]
          until jobs[job_key]
            sleep 0.1
          end
        end

      elsif is_gen_key == false
        # do nothing and fall through to return the job key of an
        # existing worker.
      else
        raise ::BackgrounDRbDuplicateKeyError
      end    
      return job_key

    end

    def schedule_worker(opts={})

      job_key = opts[:job_key]

      # If the worker is already instantiated, then we really only need
      # the job_key. Otherwise we'll need the worker class as well.
      begin
        unless jobs[job_key]
          worker_klass_constant(opts[:class])
        end
      rescue ArgumentError, NameError => e
        BackgrounDRb::ServerLogger.log_exception('middleman', e)
        return nil
      end

      if job_key
        new_worker_arg = { :class => opts[:class], 
          :args => opts[:args], :job_key => job_key
        }
      else
        new_worker_arg = {:class => opts[:class], 
          :args => opts[:args]
        }
      end


      # primitive auto-detection of trigger type, based on
      # trigger_args
      unless opts[:trigger_type]
        case opts[:trigger_args]
        when String
          opts[:trigger_type] = :cron_trigger
        when Hash
          opts[:trigger_type] = :trigger
        end
      end

      case opts[:trigger_type]
      when :cron_trigger
        # most likely bad default :)
        cron_args = opts[:trigger_args] || "0 0 0 0 0"
        trigger = BackgrounDRb::CronTrigger.new(cron_args)
      when :trigger
        trigger = BackgrounDRb::Trigger.new(opts[:trigger_args])
      else
        raise ::BackgrounDRbUnknownTriggerType
      end

      # do_work special case
      case opts[:worker_method]
      when :do_work
        opts[:worker_method_args] ||= opts[:args]
      end

      case
      when opts[:worker_method] && opts[:worker_method_args]
        args = opts[:worker_method_args].dup
        sched_proc = lambda do 
          m = MiddleMan.instance
          job_key = m.new_worker(new_worker_arg)

          case opts[:worker_method]
          when :do_work
            unless m.worker(job_key).initial_do_work
              m.worker(job_key).send(opts[:worker_method], args)
            else
              m.worker(job_key).initial_do_work = false
            end
          else
            m.worker(job_key).send(opts[:worker_method], args)
          end

        end
      when opts[:worker_method]
        sched_proc = lambda do 
          m = MiddleMan.instance
          job_key = m.new_worker(new_worker_arg)

          case opts[:worker_method]
          when :do_work
            unless m.worker(job_key).initial_do_work
              m.worker(job_key).send(opts[:worker_method], nil)
            else
              m.worker(job_key).initial_do_work = false
            end
          else
            m.worker(job_key).send(opts[:worker_method])
          end

        end
      else
        # FIXME: make this just call do_work
        #raise RuntimeError, new_worker_arg
        sched_proc = lambda do 
          m = MiddleMan.instance
          job_key = m.new_worker(new_worker_arg)
          m.worker(job_key).initial_do_work = false
        end
      end

      # TODO: format this better
      BackgrounDRb::ServerLogger.logger.info('middleman') { 
        "Loading Sechedule: #{new_worker_arg} #{opts} #{trigger}"
      }

      self.scheduler.schedule(sched_proc, trigger)
    end

    def unschedule_all
      scheduler.jobs.size.times do
        scheduler.unschedule(0)
      end
    end

    def delete_worker(key)
      m = self
      slave_obj = m[key]
      ex {
        @jobs.delete(key)
        @timestamps.delete(key)
      }
      begin
        slave_obj.shutdown 
      rescue Errno::ESRCH
      end
    end
    alias :delete_cache :delete_worker

    def cache(named_key, object)
      ex { self[named_key] = object }  
    end  

    def gc!(age)
      @timestamps.each do |job_key, timestamp|
        if timestamp < age
          delete_worker(job_key)
        end
      end  
    end  

    def worker(key)
      slave = nil
      give_up = false
      attempts = 0

      until give_up or slave 
        slave = ex { @jobs[key] }
        attempts += 1
        give_up = true if attempts == 42
        sleep 0.1
      end

      if slave
        worker = ex { slave.object }
        return WorkerProxy.new(worker)
      else
        # Should we really return nil if we can't get a worker?
        return nil
      end
    end  

    def [](key)
      ex { @jobs[key] }
    end
     
    def []=(key, val)
      ex {
        @jobs[key] = val
        @timestamps[key] = Time.now
      }
    end 
    
    def jobs
      ex { @jobs }
    end  

    def in_setup?(key)
      ex { 
        not_in_setup = lambda { |k| @in_setup[k] = true ; false }
        @in_setup.has_key?(key) ? true : not_in_setup[key]
      }
    end

    def out_of_setup(key)
      ex { @in_setup.delete(key) }
    end
    
    def timestamps
      ex { @timestamps }
    end

    def stats
      {
        :jobs => jobs,
        :timestamps => timestamps
      }
    end  
    
    private
      
    def ex
      @mutex.synchronize { yield }
    end
      
    def worker_klass_constant(klass)
      klass_string = klass.to_s.split('_').inject('') { |total,part| 
          total << part.sub(/\A\S/) {|m| m.upcase} 
      }

      if klass_string.match(/::/)
        worker_klass = klass_string.split(/::/).inject(Object) do |full,part|
          full.const_get(part)
        end
      else
        worker_klass = Object.const_get(klass_string)
      end
      worker_klass
    end
    
    def gen_key
      begin
        key = Digest::MD5.hexdigest("#{inspect}#{Time.now}#{rand}")
      end until self[key].nil?
      key
    end
  end  

end


