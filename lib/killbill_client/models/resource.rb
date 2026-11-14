require 'json'

module KillBillClient
  module Model
    class Resource

      attr_reader :clazz,
                  :etag,
                  :session_id,
                  :response

      KILLBILL_API_PREFIX = '/1.0/kb'
      KILLBILL_API_PAGINATION_PREFIX = 'pagination'

      @@attribute_names = {}

      UNKNOWN_JSON_ATTRIBUTE = [].freeze
      # class => { json key => [setter, cardinality, type] | UNKNOWN_JSON_ATTRIBUTE }
      @@json_attribute_cache = {}
      @@json_attribute_cache_lock = Mutex.new

      def initialize(hash = nil)
	@uri = nil
        # Make sure we support ActiveSupport::HashWithIndifferentAccess for Kaui
        if hash.respond_to?(:each)
          hash.each do |key, value|
            send("#{Utils.underscore key.to_s}=", value)
          end
        end
      end

      class << self

        def require_multi_tenant_options!(options, msg)
          api_key = options[:api_key] || KillBillClient.api_key
          api_secret = options[:api_secret] || KillBillClient.api_secret
          if api_key.nil? || api_secret.nil?
            raise ArgumentError, msg
          end
        end

        def head(uri, params = {}, options = {}, clazz = self)
          response = KillBillClient::API.head uri, params, options
          from_response clazz, response
        end

        def get(uri, params = {}, options = {}, clazz = self)
          response = KillBillClient::API.get uri, params, options
          from_response clazz, response
        end

        # Performs a GET request and returns the raw response body as received
        # from Kill Bill, without any model parsing or re-serialization.
        def raw_get(uri, params = {}, options = {})
          response = KillBillClient::API.get uri, params, options
          response.body
        end

        def post(uri, body = nil, params = {}, options = {}, clazz = self)
          response = KillBillClient::API.post uri, body, params, options
          from_response clazz, response
        end

        def put(uri, body = nil, params = {}, options = {}, clazz = self)
          response = KillBillClient::API.put uri, body, params, options
          from_response clazz, response
        end

        def delete(uri, body = nil, params = {}, options = {}, clazz = self)
          response = KillBillClient::API.delete uri, body, params, options
          from_response clazz, response
        end

        # Instantiates a record from an HTTP response, setting the record's
        # response attribute in the process.
        #
        # @return [Resource]
        # @param resource_class [Resource]
        # @param response [Net::HTTPResponse]
        def from_response(resource_class, response)
          case response['Content-Type']
            when nil
              response.body
            when %r{application/pdf}
              response.body
            when %r{text/html}
              response.body
            when %r{text/plain}
              response.body
            when %r{application/octet-stream}
              response.body
            when %r{text/xml}
              if response['location']
                response['location']
              else
                response.body
              end
            when %r{application/json}
              record = from_json resource_class, response.body
              if record.nil?
                record = resource_class.new
                record.uri = response['location']
              end

              session_id = extract_session_id(response)
              record.instance_eval {
                @clazz = resource_class
                @etag = response['ETag']
                @session_id = session_id
                @pagination_max_nb_records = response['X-Killbill-Pagination-MaxNbRecords'].to_i unless response['X-Killbill-Pagination-MaxNbRecords'].nil?
                @pagination_total_nb_records = response['X-Killbill-Pagination-TotalNbRecords'].to_i unless response['X-Killbill-Pagination-TotalNbRecords'].nil?
                @pagination_next_page = response['X-Killbill-Pagination-NextPageUri']
                @response = response
              }
              record
            else
              raise ArgumentError, "#{response['Content-Type']} is not supported by the library"
          end
        end

        # Instantiates a record from a JSON blob.
        #
        # @return [Resource]
        # @param resource_class [Resource]
        # @param json [String]
        # @see from_response
        def from_json(resource_class, json)
          # e.g. DELETE
          return nil if json.nil? or json.size == 0
          data = JSON.parse json

          if data.is_a? Array
            records = Resources.new
            data.each do |data_element|
              if data_element.is_a? Enumerable
                records << instantiate_record_from_json(resource_class, data_element)
              else
                # Value (e.g. String)
                records << data_element
              end
            end
            records
          else
            instantiate_record_from_json(resource_class, data)
          end
        end

        def instantiate_record_from_json(resource_class, data)
          record = resource_class.send :new

          # One hash lookup per JSON key (see json_attribute_for)
          table = @@json_attribute_cache[resource_class] || {}
          data.each do |name, value|
            entry = table[name] || json_attribute_for(resource_class, name)
            assign_json_attribute(record, entry, value) unless entry.equal?(UNKNOWN_JSON_ATTRIBUTE)
          end

          record
        end

        def assign_json_attribute(record, entry, value)
          type = entry[2]
          unless type.nil?
            if entry[1] == :many
              value = build_many(type, value) if value.is_a?(Array)
            elsif entry[1] == :one
              value = instantiate_record_from_json(type, value) if value.is_a?(Hash)
            end
          end

          # TODO Be lenient for now to support different API formats
          begin
            record.send(entry[0], value)
          rescue StandardError
            nil
          end
        end

        def build_many(type, values)
          records = []
          values.each do |val|
            records << (val.is_a?(Hash) ? instantiate_record_from_json(type, val) : val)
          end
          records
        end

        # Resolves (and caches) what to do with a JSON key for a given class:
        # [setter, cardinality, type] or UNKNOWN_JSON_ATTRIBUTE if the class doesn't have a matching setter.
        #
        # The cache is copy-on-write: readers never lock (and never see a Hash being mutated), writers are serialized.
        def json_attribute_for(resource_class, json_key)
          @@json_attribute_cache_lock.synchronize do
            table = @@json_attribute_cache[resource_class] || {}
            return table[json_key] if table.key?(json_key)

            entry = resolve_json_attribute(resource_class, json_key)
            @@json_attribute_cache = @@json_attribute_cache.merge(resource_class => table.merge(json_key => entry))
            entry
          end
        end

        def resolve_json_attribute(resource_class, json_key)
          name = Utils.underscore json_key
          setter = "#{name}=".to_sym
          return UNKNOWN_JSON_ATTRIBUTE unless resource_class.method_defined?(setter) || resource_class.private_method_defined?(setter)

          # Allow for inheritance: the closest ancestor declaring the attribute wins
          attr_desc = nil
          resource_class.ancestors.each do |ancestor|
            declared = @@attribute_names[ancestor.name]
            next if declared.nil?
            attr_desc = declared[name.to_sym]
            break unless attr_desc.nil?
          end

          [setter, attr_desc && attr_desc[:cardinality], attr_desc && attr_desc[:type]].freeze
        end

        def clear_json_attribute_cache
          @@json_attribute_cache_lock.synchronize { @@json_attribute_cache = {} }
        end

        def attribute(name)
          send('attr_accessor', name.to_sym)
          clear_json_attribute_cache
          attributes = @json_attributes ||= []

          if respond_to?(:json_attributes, true)
            json_attributes.push(name.to_s)
          else
            (class << self; self; end).
              send(:define_method, :json_attributes) { attributes }
            json_attributes.push(name.to_s)
          end
        end

        def has_many(attr_name, type = nil)
          send("attr_accessor", attr_name.to_sym)

          #add it to attribute_names
          @@attribute_names[self.name] ||= {}
          @@attribute_names[self.name][attr_name.to_sym] = {:type => type, :cardinality => :many}
          clear_json_attribute_cache
        end

        def has_one(attr_name, type = nil)
          send("attr_accessor", attr_name.to_sym)

          #add it to attribute_names
          @@attribute_names[self.name] ||= {}
          @@attribute_names[self.name][attr_name.to_sym] = {:type => type, :cardinality => :one}
          clear_json_attribute_cache
        end

        #hack to cater the api return attributes and javax attributes without editing gen scripts
        #call only after its declared as a instance_method using attr_accessor
        def create_alias(new_name, old_name)
          alias_method new_name.to_sym, old_name.to_sym #getter
          alias_method "#{new_name}=".to_sym, "#{old_name}=".to_sym #setter
          clear_json_attribute_cache
        end

        # Extract the session id from a response
        def extract_session_id(response)
          # The Set-Cookie header looks like
          # "set-cookie"=>["JSESSIONID=16; Path=/; HttpOnly", "rememberMe=deleteMe; Path=/; Max-Age=0; Expires=Sat, 17-Aug-2013 23:39:37 GMT"],
          session_cookie = response['set-cookie']
          unless session_cookie.nil?
            session_cookie.split(';').each do |chunk|
              chunk.strip!
              key, value = chunk.split('=')
              return value if key == 'JSESSIONID'
            end
          end
          nil
        end
      end #end self methods

      # Set on create call
      attr_accessor :uri

      def to_hash
        json_hash = {}
        self.class.json_attributes.each do |name|
          value = self.send(name)
          unless value.nil?
            json_hash[Utils.camelize name, :lower] = _to_hash(value)
          end
        end
        json_hash
      end

      def _to_hash(value)
        if value.is_a?(Resource)
          value.to_hash
        elsif value.is_a?(Array)
          value.map { |v| _to_hash(v) }
        else
          value
        end
      end

      def to_json(*args)
        to_hash.to_json(*args)
      end

      def refresh(options = {}, clazz=self.class)
        if @uri
          # Need to decode in case an encoding is in place (e.g. /1.0/kb/security/users/Mad%20Max/roles) , since later on
          # it will be encoded and can cause an undesired result on the call.
          unecoded_uri = URI::DEFAULT_PARSER.unescape(@uri)

          self.class.get unecoded_uri, {}, options, clazz
        else
          self
        end
      end


      def ==(o)
        o.class == self.class && o.hash == hash
      end

      alias_method :eql?, :==

      def hash
        to_hash.hash
      end
    end
  end
end
