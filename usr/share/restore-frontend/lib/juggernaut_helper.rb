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

module Juggernaut # :nodoc:
  module JuggernautHelper

    def listen_to_juggernaut_channels(channels = nil, unique_id = "null", swf_address = "juggernaut.swf")
      port = Juggernaut::CONFIG["PUSH_PORT"]
      num_tries = Juggernaut::CONFIG["NUM_TRIES"]
      num_secs = Juggernaut::CONFIG["NUM_SECS"]
      base64 = Juggernaut::CONFIG["BASE64"] ? true : false
      channels = Array(channels || Juggernaut::CONFIG["DEFAULT_CHANNELS"])
      channels = channels.map { |c| CGI.escape(c.to_s) }.to_json
      content = content_tag :div, '', :id=>'flashcontent', :style => "width:0 height:0;"
      content += javascript_tag %{Juggernaut.debug = true;} if Juggernaut::CONFIG["LOG_ALERT"] == 1
      content += javascript_tag %{Juggernaut.listenToChannels({ 
                                host: document.location.hostname, 
                                num_tries: #{num_tries}, 
                                ses_id: '#{session.session_id}', 
                                num_secs: #{num_secs}, 
                                unique_id: '#{unique_id}', 
                                swf_address: '#{swf_address}', 
                                flash_version: '8',
                                width: '1',
                                height: '1',
                                base64: #{base64}, 
                                port: #{port}, 
                                channels: #{channels}});}
      content
    end
    
  end
end
