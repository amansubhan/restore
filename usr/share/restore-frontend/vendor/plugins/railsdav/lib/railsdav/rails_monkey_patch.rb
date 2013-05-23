# Copyright (c) 2006 Stuart Eccles
# Released under the MIT License.  See the LICENSE file for more details.
class CGI #:nodoc:
  # Add @request.env['RAW_POST_DATA'] for the vegans.
  module QueryExtension 
    
  private 
    
    def read_params(method, content_length)
      case method
        when :get
          read_query
        when :post, :put, :proppatch, :propfind
          read_body(content_length)
        when :cmd
          read_from_cmdline
        else # :head, :delete, :options, :trace, :connect
          read_query
      end
    end
end # module QueryExtension
end

class CGIMethods
    def self.typecast_xml_value(value)
      case value
      when Hash
        if value.has_key?("__content__")
          content = translate_xml_entities(value["__content__"])
          case value["type"]
          when "integer"  then content.to_i
          when "boolean"  then content == "true"
          when "datetime" then Time.parse(content)
          when "date"     then Date.parse(content)
          else                 content
          end
        else
          value.empty? ? nil : value.inject({}) do |h,(k,v)|
            h[k] = typecast_xml_value(v)
            h
          end
        end
      when Array
        value.map! { |i| typecast_xml_value(i) }
        case value.length
        when 0 then nil
        when 1 then value.first
        else value
        end
      when String
        value
      else
        raise "can't typecast #{value.inspect}"
      end
    end
end

#class CGIMethods
#  def CGIMethods.parse_request_parameters(params)
#      parsed_params = {}
#
#      for key, value in params
#        value = [value] if key =~ /.*\[\]$/
#        next if key.nil?
#        if !key.nil? && !key.include?('[')
#          # much faster to test for the most common case first (GET)
#          # and avoid the call to build_deep_hash
#          parsed_params[key] = get_typed_value(value[0])
#        else
#          build_deep_hash(get_typed_value(value[0]), parsed_params, get_levels(key))
#        end
#      end
#    
#      parsed_params
#    end
#end
