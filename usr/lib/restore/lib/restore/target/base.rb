# Copyright (c) 2006, 2007 Ruffdogs Software, Inc.
# Authors: Adam Lebsack <adam@holonyx.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

module Restore
  module Target
    require 'restore/snapshot'
    require 'restore/client' if dc_edition?
    require 'restore/account'
    require 'restore/role'
    require 'gettext'
    
    class Base < ActiveRecord::Base
      include GetText
      bindtextdomain("restore")
      
      set_table_name 'targets'
      has_many :snapshots, :class_name => 'Restore::Snapshot::Base', :foreign_key => 'target_id', :dependent => :delete_all
      has_many :full_snapshots, :class_name => 'Restore::Snapshot::Base', :foreign_key => 'target_id',
        :conditions => 'end_time is not null and error is null', :order => 'id asc'
      
      has_many :revision_schedules, :class_name => 'Restore::RevisionSchedule', :foreign_key => 'target_id', :dependent => :delete_all
      
      has_many :schedules, :class_name => 'Restore::Schedule::Base', :foreign_key => 'target_id', :dependent => :delete_all

      if dc_edition?
        belongs_to :client, :class_name => 'Restore::Client', :foreign_key => 'client_id'
      end
      
      belongs_to :owner, :class_name => 'Restore::Account::User', :foreign_key => 'owner_id'
      has_many :roles, :class_name => 'Restore::Role', :foreign_key => 'target_id', :dependent => :delete_all
      

      serialize :extra, Hash
      
      validates_presence_of :name
      validates_uniqueness_of :name, :scope => :client_id
      
      
      self.abstract_class = true
      
      # cache connections and handles
      cattr_accessor :target_handles      
      class << self
        @@target_handles ||= {}
        def snapshot_class
          require_dependency "restore/snapshot"
          Restore::Snapshot::Base
        end
        
        def worker_class
          ('Restore::Worker::'+self.to_s.split(/::/)[-1])
        end
        
        
        # returns a job key
        def new_worker(method, args, options={})
          # XXX need a better unique job id
          job_id = Time.now.usec
          
          MiddleMan.new_worker(
            :class => 'TargetWorker',
            :job_key => "tw_#{job_id}",
            :args => {
              :oncomplete => options[:oncomplete],
              :session_id => options[:session_id],
              :target_class => self.to_s, 
              :method => method,
              :method_args => args
            }
          )
          return "tw_#{job_id}"
        end
        
      end
      
      def storage
        unless self.class.target_handles[self.id]
          our_socket = File.join(Restore::Config.socket_dir, "drb_#{Time.now.usec}.sock")
          DRb.start_service("drbunix://#{our_socket}")
          
          socket = File.join(Restore::Config.socket_dir, "restore_storage.sock")
          
          ro = DRbObject.new(nil, 'drbunix://'+socket)
          self.class.target_handles[self.id] = ro.get_target_handle(self.id)
        end
        self.class.target_handles[self.id]
      end
      
      
      def dav_resource_class
        require 'restore/dav_resource/target'
        Restore::DavResource::Target
      end      
      
      
      
      
      def after_destroy
        storage.destroy
      end
      
      def snapshot_class
        self.class.snapshot_class
      end
      
      def worker_class
        self.class.worker_class
      end
      
      def create_snapshot(options={})
        snapshot = self.snapshot_class.create(options.merge(:target_id => self.id))    
        snapshots << snapshot
        snapshot
      end

      def snapper_class
        module_require_dependency self[:type].underscore, 'snapper'
        
        #require "modules/#{self[:type].underscore}/snapper"
        ('Restore::Snapper::'+self[:type]).constantize
      end
      
      def create_snapper(snapshot, logger)
        if dc_edition? && client.available_space <= 0
          raise _("Quota limit reached")
        else
          self.snapper_class.new(self, snapshot, logger)
        end
      end
      

      def restorer_class
        require "modules/#{self[:type].underscore}/restorer"
        ('Restore::Restorer::'+self[:type]).constantize
      end

      def create_restorer(snapshot, logger, args={})
        self.restorer_class.new(self, snapshot, logger, args)
      end

      def latest_snapshot
        snapshots.find(:first, :order => 'id DESC')
      end

      def running_snapshot
        snapshots.last if snapshots.last && snapshots.last.running?
      end
            
      def clean_failed_snapshots
        snapshots.find(:all, :conditions => 'end_time is not null AND error is not null').each do |s|
          s.destroy
        end
      end
      
      


      def background_destroy
        if !MiddleMan.jobs.keys.include?("delete_#{self.id}")
          MiddleMan.new_worker(
            :class => 'DeleteWorker',
            :job_key => "delete_#{self.id}",
            :args => {:target_id => self.id }
            )
        end
      end

      def short_status
        if MiddleMan.jobs.keys.include?("delete_#{self.id}")
          'deleting'
        elsif s = latest_snapshot
          s.short_status
        else
          'N/A'
        end
      end

      def start_snapshot(snapshot)
        MiddleMan.new_worker(
          :class => 'SnapshotWorker',
          :job_key => "snapshot_#{self.id}",
          :args => {:target_id => self.id, :snapshot_id => snapshot.id }
        )
      end

      def start_restorer(snapshot_id, args={})
        MiddleMan.new_worker(
          :class => 'RestoreWorker',
          :job_key => "restore_#{self.id}",
          :args => {:target_id => self.id, :snapshot_id => snapshot_id, :extra_args => args }
        )
      end

      def restore_running?
        MiddleMan.jobs.keys.include?("restore_#{self.id}")
      end
      
      def clean_snapshots
        snapshots.each do |s|
    		  s.destroy
    	  end
    	  self.size = self.snapshots.inject(0) {|s,snap| s += snap.size}
        self.save
    	  
  	  end
  	  
  	  def type_name
  	    self[:type]
  	  end
  	  
  	  protected
  	  def self.compute_type(type_name)
        modularized_name = type_name_with_module(type_name)
        
        begin
          class_eval(type_name, __FILE__, __LINE__)
        rescue NameError => e
          class_eval('Unknown', __FILE__, __LINE__)
        end
      end
      
    end
    
    class Unknown < Base
    
    end
    
  end
end

