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

require 'zip/zip'

module Zip
  class ZipEntry
    def set_extra_attributes(file_type, uid, gid, perms)
      case file_type
      when 'D'
        @ftype = :directory
      when 'F'
        @ftype = :file
      when 'L'
        @ftype = :symlink
      end
      @unix_uid = uid
      @unix_gid = gid
      @unix_perms = perms
    end

    def write_local_entry(io)   #:nodoc:all
      #@localHeaderOffset = io.tell
      io <<
      [LOCAL_ENTRY_SIGNATURE,
      0,
      @gp_flags ? @gp_flags : 0,
      @compression_method,
      @time.to_binary_dos_time,
      @time.to_binary_dos_date,
      @crc,
      @compressed_size,
      @size,
      @name ? @name.length   : 0,
      @extra? @extra.local_length : 0 ].pack('VvvvvvVVVvv')
      io << @name
      io << (@extra ? @extra.to_local_bin : "")
    end  
  end

  class ZipCentralDirectory
    def write_to_stream(io, offset)
      @entrySet.each { |entry| entry.write_c_dir_entry(io) }
      write_e_o_c_d(io, offset)
    end
  end
end

class Zipfile
  cattr_accessor :logger
  @@logger = nil
  
  def initialize(compress=false, level=nil)
    @output_buffer = ''
    #@files = []
    @file_hash = {}
    @finished = false
    @cur_entry = nil
    @entries = []
    @sent_size = 0
    @compress = compress
    @compression_level = level
  end

  def log_info(str)
    logger.info(str) if logger
  end

  def log_error(str)
    logger.error(str) if logger
  end


  def add_file(file)
    log_info "Zipfile added: #{file[:filename]}"
    @file_hash[file[:path]] = file
  end


  def next_file
    path,file = @file_hash.shift
    file
  end

  def zip_file(file)
    name = file[:path][1..-1]
    log_info "Zipping up #{name}"
    case file[:type]
    when 'D':
      name += '/'

      e = Zip::ZipEntry.new
      e.name = name
      e.compression_method = 0
      e.localHeaderOffset = @sent_size + @output_buffer.length
      e.set_extra_attributes(:directory, file[:extra][:uid], file[:extra][:gid], file[:extra][:mode])
      e.write_local_entry(@output_buffer)
      @entries << e
    when 'L':
      e = Zip::ZipEntry.new
      e.name = name
      e.compression_method = 0
      e.size = file[:extra][:readlink].length
      e.compressed_size = e.size
      e.crc = Zlib::crc32(file[:extra][:readlink])
      e.set_extra_attributes(:symlink, file[:extra][:uid], file[:extra][:gid], file[:extra][:mode])
      e.localHeaderOffset = @sent_size + @output_buffer.length
      e.write_local_entry(@output_buffer)
      @entries << e
      @output_buffer << file[:extra][:readlink]
    when 'F':
      @cur_fd = file[:storage].call.open('r')
      @cur_entry = Zip::ZipEntry.new
      @cur_entry.gp_flags = 1<<3
      @cur_entry.name = name

      if @compress
        @cur_entry.compression_method = Zip::ZipEntry::DEFLATED
        @cur_compressor = Zip::Deflater.new(@output_buffer, @compression_level)
      else
        @cur_entry.compression_method = Zip::ZipEntry::STORED
        @cur_compressor = Zip::PassThruCompressor.new(@output_buffer)
      end

      @cur_entry.set_extra_attributes(:file, file[:extra][:uid], file[:extra][:gid], file[:extra][:mode])
      @cur_entry.localHeaderOffset = @sent_size + @output_buffer.length
      @cur_entry.write_local_entry(@output_buffer)
                  
    end
  end


  def read(size=32768)
    while(@output_buffer.length < size) do

      # we have an open file descriptor.
      # continue reading.
      if @cur_fd
        if @cur_fd.eof?
          @cur_fd.close
          @cur_fd = nil;
          
          @cur_compressor.finish
          @cur_entry.compressed_size = @sent_size + @output_buffer.length - @cur_entry.localHeaderOffset - @cur_entry.local_header_size
          @cur_entry.size = @cur_compressor.size
          @cur_entry.crc = @cur_compressor.crc
          @entries << @cur_entry
          @cur_entry = nil
          @cur_compressor = nil
        else
          data = @cur_fd.read(size)          
          @cur_compressor << data          
          @cur_entry.size += data.length
        end
      elsif (file = next_file)
        # no open file.  try starting the next
        begin
          zip_file(file)
        rescue => e
          log_error $!
          log_error e.backtrace.join("\n")
        end
      else
        # no more files!
        if !@finished
          # done with all the files.
          cdir = Zip::ZipCentralDirectory.new(@entries, 'Created by RESTORE')
          log_info "Finishing file"
          cdir.write_to_stream(@output_buffer, @sent_size + @output_buffer.length)
          @finished = true
        end
        break
      end
    end # loop


    ret = @output_buffer[0..(size-1)]
    @output_buffer[0..(size-1)] = ''
    if ret.length == 0 && @finished
      return nil
    else
      @sent_size += ret.length
      return ret
    end
  end
end



