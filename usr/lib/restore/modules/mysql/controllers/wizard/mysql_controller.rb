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


class Wizard::MysqlController <  Wizard::BaseController

  @@steps = [
  'server',
  'browse',
  'finalize']

  protected
  def load_session
    super
    if session[:mysql_browser_root]
      @mysql_browser_root = session[:mysql_browser_root]
    end
  end

  def save_session
    if @mysql_browser_root
      session[:mysql_browser_root] = @mysql_browser_root
    end
  end
  
  def self.target_class
    Restore::Target::Mysql
  end

  def setup_step(from, to)
    super
    case self.class.steps[to]
    when 'browse'
      if from < to
        @mysql_browser_root = MysqlWizardTree::Server.new(
        @target.hostname, @target.port, @target.username, @target.password
        )
      end
    end
  end

  def process_step_input(from, to)
    case steps[from]
    when 'server'
      @target.hostname = params[:target][:hostname]
      @target.port = params[:target][:port]
      @target.username = params[:target][:username]
      @target.password = params[:target][:password]
    when 'browse'
      @target.included = @mysql_browser_root.selected
      @mysql_browser_root.children.each do |id,db|
        database = Restore::Modules::Mysql::Database.new(
        :name => db.id,
        :target => @target,
        :included => (@mysql_browser_root.selected == db.selected) ? nil : db.selected
        )
        if db.selected
          #database.logs << Restore::Modules::Mysql::DatabaseLog.new(
          #:event => 'A',
          #:target => @target
          #)
        end
        @target.databases << database

        if db.children
          db.children.each do |id,t|
            object = case t.class
            when MysqlWizardTree::Table
              table = Restore::Modules::Mysql::Table.new(
              :name => t.id,
              :target => @target,
              :included => (db.selected == t.selected) ? nil : t.selected
              )
              if t.selected
                #table.logs << Restore::Modules::Mysql::TableLog.new(
                #:event => 'A',
                #:target => @target,
                #:table_type => 'table'
                #)
              end
              database.tables << table
            when MysqlWizardTree::View
              view = Restore::Modules::Mysql::Table.new(
              :name => t.id,
              :target => @target,
              :included => (db.selected == t.selected) ? nil : t.selected
              )
              if t.selected
                #view.logs << Restore::Modules::Mysql::TableLog.new(
                #:event => 'A',
                #:target => @target,
                #:table_type => 'view'
                #)
              end
              database.tables << view

            when MysqlWizardTree::Routine
              #Restore::Modules::Mysql::Routine.new(
              #  :name => t.id,
              #  :target => @target,
              #  :included => (db.selected == t.selected) ? nil : t.selected
              #)
            end
          end
        end
      end
    end
    super
  end  

  def find_tree(id)
    if id == 'server'
      @mysql_browser_root
    end
  end
end
