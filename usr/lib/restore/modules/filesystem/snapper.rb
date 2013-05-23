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
  module Snapper
    require 'restore/snapper'
    
    class Filesystem < Restore::Snapper::Base

      def prepare
        super
        
        target.connection.create_table "snapshot_log_#{@snapshot.id}", :temporary => true, :id => false do |t|
          t.column "snapshot_id",   :integer
          t.column "file_id",       :integer,  :limit => 20, :default => 0,     :null => false
          t.column "event",         :string,   :limit => 1
          t.column "file_type",     :string,   :limit => 1
          t.column "mtime",         :datetime
        end
        
        target.connection.execute("insert into snapshot_log_#{@snapshot.id} select snapshot_id,file_id,event,file_type,mtime from filesystem_logs where target_id='#{target.id}'  and btime is not null")
        target.connection.add_index "snapshot_log_#{@snapshot.id}", ["file_id"], :name => "file_id"
                
        prepare_file(nil, make_attrs('', target.root_directory.filename))
        
        target.connection.execute("drop temporary table snapshot_log_#{@snapshot.id}")
        
      end

      def execute
        super
        copy_directory(target.root_directory)
      end

      def cleanup
        super
        cleanup_file(target.root_directory)
      end

      protected
      def prepare_file(dir, attrs)
        if dir.nil?
          parent_path = ''
          parent_id = -1
        else
          parent_path = dir.path
          parent_id = dir.id
        end

        update_status(:prepare_file => parent_path+'/'+attrs[:filename])
        event = nil
        size = 0
        filename = attrs[:filename]
        
        if dir.nil?
          file = target.root_directory
        elsif !(file = dir.children.find_by_filename(filename))
          file = Restore::Modules::Filesystem::File.create(
          :target => @target,
          :parent => dir,
          :target_id => @target.id,
          :parent_id => dir.id,
          :filename => filename,
          :path => dir.path+'/'+filename
          )

          # file never existed...  it's an Add event
          event = 'A'
        else
          # file entry exists, check for log
          log = target.connection.select_one("SELECT * FROM snapshot_log_#{@snapshot.id} WHERE (file_id = #{file.id}) ORDER BY snapshot_id desc LIMIT 1")
          
          #if lastlog = file.last_log
          if log
            # XXX Make sure we're getting ownership changes!
            if log['event'] == 'D'
              # file re-added
              event = 'A'
            elsif log['file_type'] != attrs[:type]
              #file type changed
              event = 'M'
            elsif log['mtime'] && ActiveRecord::ConnectionAdapters::Column.string_to_time(log['mtime']) < attrs[:mtime]
              #file modified
              event = 'M'
            else
              # no modifications, send size up
            end
          else
            # no previous log, file is added
            event = 'A'
          end
        end

        size = 0
        if(attrs[:type] == 'D')
          if prepare_directory(file)
            # something in the dir was modified. log the dir
            event ||= 'M'
          end
        end

        if !event.nil?
          log = file.logs.create(
          :snapshot_id => snapshot.id,
          :target_id => target.id,
          :target => @target,
          :event => event,
          :file_type => attrs[:type],
          :mtime => attrs[:mtime])
          
          #p = file.path
          #p += '/' if attrs[:type] == 'D'
          logger.info "#{log.event}        #{dir.path}/#{file.filename}" if attrs[:type] != 'D'
          return true
        end

        return false
      end # prepare_file

      # Scan the contents of a directory for changes
      # this is done inside the prepare phase
      def prepare_directory(dir)
        logger.info "Scanning #{dir.path}/"
        modified = false

        # these hold attribute hashes for all files in this directory
        dirs = []
        files = []

        unless dir.included?
          # only log files that are included
          dir.children.each do |c|
            next unless c.deep_included?
            # XXX this attrs thing could be handled a bit more gracefuly
            attrs = { :filename => c.filename }
            begin
              attrs = make_attrs(dir.path, c.filename)
            rescue => e
              logger.error e.to_s
              attrs[:error] = e.to_s
            end
            
            if attrs[:type] == 'D'
              dirs << attrs
            else
              files << attrs
            end

          end
        else          
          # this directory is included, log all files
          found_files = []          
          read_directory(dir) do |f|
            # XXX this attrs thing could be handled a bit more gracefuly
            attrs = {:filename => f }
            begin
              attrs = make_attrs(dir.path, f)
            rescue => e
              attrs[:error] = e.to_s
              logger.error e.to_s
            end
            if attrs[:type] == 'D'
              dirs << attrs
            else
              files << attrs
            end
            found_files << f
          end

          # now find the files that have been deleted from this dir
          dir.children.each do |c|
            unless found_files.include?(c.filename)
              if (l = c.logs.last) && (l.event != 'D')
                prune_file(c)
                modified = true
              end
            end
          end
        end
        
        (files+dirs).each do |f|
          modified = true if prepare_file(dir, f)
        end        
        return modified
      end

      
      def read_directory(dir)
        raise "abstract function"
      end

      def prune_file(file)
        file.children.each do |c|
          prune_file(c)
        end
        log = file.logs.create(
          :snapshot_id => snapshot.id,
          :target_id => target.id,
          :target => @target,
          :event => 'D')
        logger.info "#{log.event} #{file.path}"
      end
      
      # yay recursion
      # the commented code in here is for bypassing activerecord.
      # we may use it some day.
      def copy_directory(dir)
        dirlog = dir.logs.find_by_snapshot_id(snapshot.id)
        
        if dirlog && (dirlog.event == 'A' || dirlog.event == 'M')
          dirlog.storage.mkdir
          begin
            dattrs = copy_file(dirlog)
            dattrs[:local_size] = dirlog.storage.size
            dattrs[:btime] = Time.now
          rescue
            # silent
          end
          
          #children = target.connection.select_all("SELECT * FROM filesystem_files WHERE (filesystem_files.parent_id = #{dir.id}) ORDER BY filename")
          #children.each do |f|

          dir.children.each do |f|
            #if log = target.connection.select_one("SELECT * FROM filesystem_logs WHERE (filesystem_logs.file_id = #{f['id']}) AND (filesystem_logs.`snapshot_id` = #{snapshot.id}) AND (filesystem_logs.event='A' || filesystem_logs.event='M') LIMIT 1")
            if (log = f.logs.find_by_snapshot_id(snapshot.id)) && (log.event == 'A' || log.event == 'M')
              #logger.info "Copying #{f['path']}"
              logger.info "Copying #{f.path}"
              #if log['file_type'] == 'D'
              if log.file_type == 'D'
#                copy_directory(dir.children.find(f['id']))
                copy_directory(f)
              else
                attrs = {}
                begin
                  attrs = copy_file(log)                  
                rescue => e
                  attrs = {:error => $!.to_s}
                end              
                log.update_attributes(attrs)
              end
            end
          end # dir.children
          dirlog.update_attributes(dattrs)
        end
      end

      def copy_file(log)
      end


      def cleanup_file(file)
        #logger.info "Checking #{file.path} (id #{file.id})"
        
        # this is implied.  always keep one revision
        options = {
          :conditions => "event != 'D' AND pruned=0",
          :order => 'btime desc',
          :limit => 1
        }
        keep = file.logs.find(:all, options).collect {|l| l.id}
        
        @target.revision_schedules.each do |rs|
          since = rs.calc_since(snapshot.created_at)
          if rs.interval == 0
            # no interval. keep all
            options = {
              :conditions => ["event != 'D' AND btime >= ? AND pruned=0", since],
              :order => 'btime desc'
            }
            keep += file.logs.find(:all, options).collect {|l| l.id}    
          else
            options = {
               :conditions => ["event != 'D' AND btime >= ? AND pruned=0", since],
               :order => 'btime asc'
            }

            cutoff = since
            file.logs.find(:all, options).each do |l|
              while l.btime > (cutoff + rs.interval) do
                cutoff += rs.interval
              end

              if (l.btime >= cutoff) && (l.btime < cutoff + rs.interval)
                keep << l.id
                # move to for example, next hour
                # but we need to skip all logs until then
                cutoff += rs.interval
              end
            end
          end
        end
        keep.uniq!

        file.children.find(:all).each do |c|
          cleanup_file(c)
        end

        file.logs.find(:all, :conditions => "event != 'D' AND btime is not null AND pruned=0", :order => 'btime asc').each do |log|
          if keep.include?(log.id)
            #puts "\tKeep #{log.event} #{log.btime}"
          else
            logger.info "Deleting '#{file.path}' from snapshot #{log.snapshot.id}"
            log.prune
          end
        end
      end
    end
  end
end
