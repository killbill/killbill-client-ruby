require 'cgi'
require 'net/https'
require 'json'

module KillBillClient
  class API
    module Net
      module HTTPAdapter
        # A hash of Net::HTTP settings configured before the request.
        #
        # @return [Hash]
        def net_http
          @net_http ||= {}
        end

        # Used to store any Net::HTTP settings.
        #
        # @example
        #   KillBillClient::API.net_http = {
        #     :verify_mode => OpenSSL::SSL::VERIFY_PEER,
        #     :ca_path     => "/etc/ssl/certs",
        #     :ca_file     => "/opt/local/share/curl/curl-ca-bundle.crt"
        #   }
        attr_writer :net_http

        private

        RE_PATH = /(\/1.0\/kb(?:\/\w+){1,2}\/)\w+-\w+-\w+-\w+-\w+(\/\w+)*/

        METHODS = {
            :head => ::Net::HTTP::Head,
            :get => ::Net::HTTP::Get,
            :post => ::Net::HTTP::Post,
            :put => ::Net::HTTP::Put,
            :delete => ::Net::HTTP::Delete
        }

        def request(method, relative_uri, options = {})
          head = headers.dup
          head.update options[:head] if options[:head]
          head.delete_if { |_, value| value.nil? }

          uri = base_uri + URI.escape(relative_uri)


          # Plugin properties are passed in the options but we want to send them as query parameters,
          # so remove with from global hash and insert them under :params
          plugin_properties = options.delete :pluginProperty
          if plugin_properties && plugin_properties.size > 0
            options[:params][:pluginProperty] = plugin_properties.map { |p| "#{p.key}=#{p.value}" }
          end


          if options[:params] && !options[:params].empty?
            pairs = options[:params].map { |key, value|
              # If the value is an array, we 'demultiplex' into several
              if value.is_a? Array
                internal_pairs = value.map do |simple_value|
                  "#{CGI.escape key.to_s}=#{CGI.escape simple_value.to_s}"
                end
                internal_pairs
              else
                "#{CGI.escape key.to_s}=#{CGI.escape value.to_s}"
              end
            }
            pairs.flatten!
            uri += "?#{pairs.join '&'}"
          end
          request = METHODS[method].new uri.request_uri, head

          # Configure multi-tenancy headers, if enabled
          if (options[:api_key] || KillBillClient.api_key) && (options[:api_secret] || KillBillClient.api_secret)
            request['X-Killbill-ApiKey'] = options[:api_key] || KillBillClient.api_key
            request['X-Killbill-ApiSecret'] = options[:api_secret] || KillBillClient.api_secret
          end

          # Configure RBAC, if enabled
          username = options[:username] || KillBillClient.username
          password = options[:password] || KillBillClient.password
          if username and password
            request.basic_auth(*[username, password].flatten[0, 2])
          end
          session_id = options[:session_id]
          if session_id
            request['Cookie'] = "JSESSIONID=#{session_id}"
          end

          if options[:accept]
            request['Accept'] = options[:accept]
          end
          if options[:body]
            request['Content-Type'] = options[:content_type] || content_type
            request.body = options[:body]
          end
          if options[:etag]
            request['If-None-Match'] = options[:etag]
          end
          if options[:locale]
            request['Accept-Language'] = options[:locale]
          end

          # Add auditing headers, if needed
          if options[:user]
            request['X-Killbill-CreatedBy'] = options[:user]
          end
          if options[:reason]
            request['X-Killbill-Reason'] = options[:reason]
          end
          if options[:comment]
            request['X-Killbill-Comment'] = options[:comment]
          end

          #
          # Extract profiling data map if it exists and set X-Killbill-Profiling-Req HTTP header
          # (there will be no synchronization done, so if multiple threads are running they should probably
          # pass a per-tread profiling Map)
          #
          cur_thread_profiling_data = nil
          if options[:profilingData]
            request['X-Killbill-Profiling-Req'] = 'JAXRS'
            cur_thread_profiling_data = options[:profilingData]
          end


          http = ::Net::HTTP.new uri.host, uri.port
          http.use_ssl = uri.scheme == 'https'
          net_http.each_pair { |key, value| http.send "#{key}=", value }

          if KillBillClient.logger
            KillBillClient.log :info, '===> %s %s' % [request.method, uri]
            headers = request.to_hash
            headers['authorization'] &&= ['Basic [FILTERED]']
            KillBillClient.log :debug, headers.inspect
            if request.body && !request.body.empty?
              KillBillClient.log :debug, request.body
            end
            start_time = Time.now
          end

          response = http.start { http.request request }
          code = response.code.to_i

          # Add profiling data if required
          if cur_thread_profiling_data && response.header['X-Killbill-Profiling-Resp']
            profiling_header = JSON.parse response.header['X-Killbill-Profiling-Resp']
            jaxrs_profiling_header = profiling_header['rawData'][0]
            key = nil
            if RE_PATH.match(uri.path)
              second_arg = $2.nil? ? "" : $2
              key = "#{method}:#{$1}uuid#{second_arg}"
            else
              key = "#{method}:#{uri.path}"
            end
            if cur_thread_profiling_data[key].nil?
              cur_thread_profiling_data[key] = []
            end
            cur_thread_profiling_data[key] << jaxrs_profiling_header['durationUsec']
          end


          if KillBillClient.logger
            #noinspection RubyScope
            latency = (Time.now - start_time) * 1_000
            level = case code
                      when 200...300 then
                        :info
                      when 300...400 then
                        :warn
                      when 400...500 then
                        :error
                      else
                        :fatal
                    end
            KillBillClient.log level, '<=== %d %s (%.1fms)' % [
                code,
                response.class.name[9, response.class.name.length].gsub(
                    /([a-z])([A-Z])/, '\1 \2'
                ),
                latency
            ]
            KillBillClient.log :debug, response.to_hash.inspect
            KillBillClient.log :debug, response.body if response.body
          end

          case code
            when 200...300 then
              response
            else
              raise ERRORS[code].new request, response
          end
        end
      end
    end

    extend Net::HTTPAdapter
  end
end
