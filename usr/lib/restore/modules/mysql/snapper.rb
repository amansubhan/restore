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
  module Modules
    module Mysql
      require 'tempfile'
      class DatabaseCopier
        include GetText
        bindtextdomain("restore")
        
        attr_reader :logger
        def initialize(target, database, snapshot, logger)
          
          @target, @database, @snapshot, @logger = target, database, snapshot, logger

          #line buffer
          @lines = []
        end
        
        # reads input, but keeps a buffer of the next 2 lines
        # stored in @lines
        def readlines(&block)
          loop do
            if @lines.size < 3 && !@f.eof?
              @lines << @f.readline
            elsif @lines.size == 0 && @f.eof?
              break
            else
              yield @lines.shift
            end
          end
        end

        def new_table?(line)
          if line =~ /^\-\-/ && @lines[1] =~ /^\-\-/ &&
            matches = /^\-\- Table structure for table `(.*?)`$/.match(@lines[0])
            return matches[1]
          end
          return false
        end

        def new_view?(line)
          if line =~ /^\-\-/ && @lines[1] =~ /^\-\-/ &&
            matches = /^\-\- Final view structure for view `(.*?)`$/.match(@lines[0])
            return matches[1]
          end
          return false
        end

        def section_change?(line)
          new_table?(line) || new_view?(line) || @f.eof
        end

        def copy
          bytes = 0
          tables = @database.tables.collect {|t|
            if table_log = t.logs.find_by_snapshot_id(@snapshot.id)
              "'#{t.name}'" if (table_log.event == 'A' || table_log.event == 'M')
            end
          }.compact.join(' ')

          mycnf = Tempfile.new('my.cnf')
          mycnf.puts "[client]"
          mycnf.puts "password=#{@target.password}"
          mycnf.close

          cmd = "mysqldump --defaults-extra-file=#{mycnf.path} -u #{@target.username} -h #{@target.hostname} -P #{@target.port} --opt --routines #{@database.name} #{tables}"
          IO.popen(cmd) {|@f|
            readlines do |line|
              begin
                if tablename = new_table?(line)
                  @lines.unshift line
                  bytes += copy_table(tablename)
                elsif viewname = new_view?(line)
                  @lines.unshift line
                  bytes += copy_view(viewname)
                elsif line !~ /^$/
                  #logger.debug "other: "+line
                end
              rescue => e
                logger.error $!.to_s
              end
            end
          }
          mycnf.unlink
          return bytes
        end

        def copy_table(tablename)
          if table = @database.tables.find_by_name(tablename)
            if table_log = table.logs.find_by_snapshot_id(@snapshot.id)
              if(table_log.event == 'A' || table_log.event == 'M')
                logger.info _("Copying")+" #{@database.name}.#{tablename}"
                #md5 = Digest::MD5.new
                
                size = 0
                table_log.storage.open('w') do |local|
                  readlines do |line|
                    local << line
                    size += line.length
                    #md5 << line
                    break if line =~ /^UNLOCK TABLES;$/
                  end
                end
                # save table backup info
                table_log.btime = Time.now
                table_log.local_size = table_log.storage.size
                table_log.remote_size = size
                table_log.save
                return table_log.remote_size
              end
            end
          end
          0
        end # copy_table

        def copy_view(viewname)
          if view = @database.tables.find_by_name(viewname)
            if view_log = view.logs.find_by_snapshot_id(@snapshot.id)
              if(view_log.event == 'A' || view_log.event == 'M')
                logger.info _("Copying view")+" #{@database.name}.#{viewname}"
                size = 0
                view_log.storage.open('w') do |local|
                  readlines do |line|
                    local << line
                    size += line.length
                    break if line =~ /^\/\*\d+ VIEW/
                  end
                end
                # save table backup info
                view_log.btime = Time.now
                view_log.local_size = view_log.storage.size
                view_log.remote_size = size
                view_log.save
                return view_log.remote_size
              end
            end
          end
          0
        end # copy_view

      end
    end
  end

  module Snapper
    require 'restore/snapper'
    class Mysql < Restore::Snapper::Base

      def prepare
        super
        @dbh = ::Mysql.real_connect(target.hostname, target.username, target.password, nil, target.port)
        if target.included
          # only log databases that are included
          target.databases.each do |database|
            next unless database.deep_included?
            begin
              prepare_database(database.name)
            rescue => e
              logger.error e.to_s
            end
          end
        else
          # this server is included, log all databases
          found_databases = []
          @dbh.query("SHOW DATABASES WHERE `database`!='information_schema'").each do |row|
            dbname = row[0]
            begin
              prepare_database(dbname)
              found_databases << dbname
            rescue => e
              logger.error e.to_s
            end
          end          
          # now find the databases that have been deleted from this server
          target.databases.each do |database|
            if !found_databases.include?(database.name) &&
              (l = database.last_log) &&
              l.event != 'D'

              log = database.logs.create(
              :snapshot_id => snapshot.id,
              :target_id => target.id,
              :target => @target,
              :event => 'D')
              logger.info "#{log.event} #{database.name}"
            end
          end
        end
      end


      def execute
        super
        @copied_bytes = 0
        target.databases.each do |database|
          if log = database.logs.find_by_snapshot_id(snapshot.id)
            if(log.event == 'A' || log.event == 'M')
              attrs = {}
              begin
                logger.info _("Copying")+" #{database.name}"
                #FileUtils.mkdir_p(log.local_path)
                log.storage.mkdir
                
                local_size = log.storage.size
                remote_size = Restore::Modules::Mysql::DatabaseCopier.new(target, database, snapshot, logger).copy
                attrs = {
                  :btime => Time.now,
                  :local_size => local_size,
                  :remote_size => remote_size
                }
              rescue => e
                logger.error e.to_s
                attrs = {:error => $!.to_s+"\n"+e.backtrace.join("\n")}
              end
              log.update_attributes(attrs)
            end
          end
        end
      end

      def cleanup
        super
        target.databases.each do |database|
          cleanup_object(database)
        end
      end

      protected
      def prepare_database(dbname)
        event = nil
        # find database entry
        
        if database = @target.databases.find_by_name(dbname)
          return false unless database.deep_included?
          # database entry exists, check for log
          if lastlog = database.last_log
            if lastlog.event == 'D'
              # database re-added
              event = 'A'
            end
          else
            # no previous log, database is added
            event = 'A'
          end
        else
          # database never existed...  it's an Add event
          database = Restore::Modules::Mysql::Database.create(
          :target => @target,
          :target_id => @target.id,
          :name => dbname
          )
          event = 'A'
        end

        # go thru the objects (tables, views, functions)
        if !database.included?
          # only log tables that are included
          database.tables.each do |table|
            next unless table.included?
            attrs = {}
            begin
              row = @dbh.query("SELECT `TABLE_TYPE`,`ENGINE`,`UPDATE_TIME`,`TABLE_COLLATION` FROM `information_schema`.`TABLES` WHERE `TABLE_SCHEMA`='#{database.name}' AND `TABLE_NAME`='#{table.name}'").fetch_row
              attrs[:mtime] = Time.parse(row[2]) rescue nil
              attrs[:table_engine] = row[1]
              attrs[:table_type] = row[0]
            rescue => e
              attrs[:error] = e.to_s
              logger.error e.to_s
            end
            event ||= 'M' if prepare_table(database, table.name, attrs)
          end
        else
          # this database is included, log all objects
          event ||= 'M' if prepare_tables(database)
        end

        return false if event.nil?
        log = database.logs.create(
        :snapshot_id => snapshot.id,
        :target_id => target.id,
        :target => @target,
        :event => event)
        logger.info "#{log.event} #{database.name}"
        return true
      end

      def prepare_tables(database)
        modified = false
        found_tables = []
        @dbh.query("SELECT `TABLE_NAME`,`TABLE_TYPE`,`ENGINE`,`UPDATE_TIME`,`TABLE_COLLATION` FROM `information_schema`.`TABLES` WHERE `TABLE_SCHEMA`='#{database.name}'").each do |row|
          tablename = row[0]
          attrs = {}
          attrs[:table_engine] = row[2]
          attrs[:table_type] = row[1]
          attrs[:mtime] = Time.parse(row[3]) rescue nil

          modified = true if prepare_table(database, tablename, attrs)
          found_tables << tablename
        end
        # now find the databases that have been deleted from this server
        database.tables.each do |table|
          if !found_tables.include?(table.name) && (l = table.last_log) && l.event != 'D'
            log = table.logs.create(
            :snapshot_id => snapshot.id,
            :target_id => target.id,
            :target => @target,
            :event => 'D')
            logger.info "#{log.event} #{table.database.name}.#{table.name}"
            modified = true
          end
        end
        modified
      end

      def prepare_table(database, tablename, attrs={})
        event = nil
        # find table entry
        if table = database.tables.find_by_name(tablename)
          # table entry exists, check for log
          if lastlog = table.last_log
            if lastlog.event == 'D'
              # table re-added
              event = 'A'
            elsif lastlog.table_engine != attrs[:table_engine]
              #table engine changed
              event = 'M'
            elsif lastlog.table_type != attrs[:table_type]
              #table type changed
              event = 'M'
            elsif attrs[:mtime] && lastlog.mtime && lastlog.mtime < attrs[:mtime]
              # table modified
              event = 'M'
            else
              # no mtime (not tracked by innodb), table modified
              event = 'M'
            end
          else
            # no previous log, table is added
            event = 'A'
          end
        else
          table = database.tables.create(
          :target => @target,
          :target_id => @target.id,
          :name => tablename
          )
          # table never existed...  it's an Add event
          event = 'A'
        end

        return false if event.nil?
        log = table.logs.create(
        :snapshot_id => snapshot.id,
        :target_id => target.id,
        :target => @target,
        :database_id => database.id,
        :event => event,
        :table_engine => attrs[:table_engine],
        :table_type => attrs[:table_type],
        :mtime => attrs[:mtime])
        logger.info "#{log.event} #{database.name}.#{table.name}"
        return true
      end

      def cleanup_object(object)
        # this is implied.  always keep one revision
        options = {
          :conditions => "event != 'D' AND pruned=0",
          :order => 'btime desc',
          :limit => 1
          }
        keep = object.logs.find(:all, options).collect {|l| l.id}

        @target.revision_schedules.each do |rs|
          since = rs.calc_since(snapshot.created_at)
          if rs.interval == 0
            # no interval. keep all
            options = {
              :conditions => ["event != 'D' AND btime >= ? AND pruned=0", since],
              :order => 'btime desc'
              }
            keep += object.logs.find(:all, options).collect {|l| l.id}    
          else
            options = {
              :conditions => ["event != 'D' AND btime >= ? AND pruned=0", since],
              :order => 'btime asc'
              }

            cutoff = since
            object.logs.find(:all, options).each do |l|
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

        if object.class == Restore::Modules::Mysql::Database
          object.tables.each do |table|
            cleanup_object(table)
          end
        end

        object.logs.find(:all, :conditions => "event != 'D' AND btime is not null AND pruned=0", :order => 'btime asc').each do |log|
          unless keep.include?(log.id)
            if object.class == Restore::Modules::Mysql::Database
              logger.info(_("Deleting '%s' from snapshot %s") % [object.name, log.snapshot.id])
            else
              logger.info(_("Deleting '%s' from snapshot %s") % ["#{object.database.name}.#{object.name}", log.snapshot.id])      
            end
            log.prune
          end
        end
      end
    end
  end
end
