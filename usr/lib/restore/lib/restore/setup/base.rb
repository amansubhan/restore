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


require 'termios'

module Restore
  module Setup
    class Base
      class << self
        def ask(question, default, options={})
          options = {:echo => true}.merge(options)

          $stdout.print "#{question}"
          $stdout.print " [#{default}]" if default
          $stdout.print ": "
          $stdout.flush

          if options[:echo]
            answer = $stdin.gets.chomp
          else
            begin
              term = Termios::getattr($stdout)
              term.c_lflag &= ~Termios::ECHO
              Termios::setattr($stdout, Termios::TCSANOW, term)
              answer = $stdin.gets.chomp
            ensure
              term.c_lflag |= Termios::ECHO
              Termios::setattr($stdout, Termios::TCSANOW, term)
            end
          end

          answer = default if answer.empty? && default
          puts ""
          answer
        end

        def ask_bool(question, default = true)
          loop do
            $stdout.print "#{question}"
            if default == true
              $stdout.print " [Yn]"
            elsif default == false
              $stdout.print " [yN]"
            elsif default.nil?
              $stdout.print " [yn]"
            end
            $stdout.print ": "
            $stdout.flush

            answer = $stdin.gets.chomp
            puts ''
            if answer.empty?
              next if default.nil?
              answer = default
            elsif answer =~ /^y/i
              answer = true
            elsif answer =~ /^n/i
              answer = false
            else
              next
            end
            return answer
          end
        end
      end

    end
  end
end