require 'json'

module KillBillClient
  module Model
    class Resource

      KILLBILL_API_PREFIX = '/1.0/kb/'
      @@attribute_names = {}

      class << self
        def head(uri, params = {}, options = {}, clazz = self)
          response = KillBillClient::API.head uri, params, options
          from_response clazz, response
        end

        def get(uri, params = {}, options = {}, clazz = self)
          response = KillBillClient::API.get uri, params, options
          from_response clazz, response
        end

        def post(uri, body = nil, params = {}, options = {}, clazz = self)
          response = KillBillClient::API.post uri, body, params, options
          from_response clazz, response
        end

        def put(uri, body = nil, params = {}, options = {}, clazz = self)
          response = KillBillClient::API.put uri, body, params, options
          from_response clazz, response
        end

        def delete(uri, params = {}, options = {}, clazz = self)
          response = KillBillClient::API.delete uri, params, options
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
          when %r{application/pdf}
            response.body
          when %r{application/json}
            record = from_json resource_class, response.body
            record.instance_eval { @etag, @response = response['ETag'], response }
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

          instantiate_record_from_json(self, data)
        end

        def instantiate_record_from_json(resource_class, data)
          record = resource_class.send :new
          
          data.each do |name, value|
            name = Utils.underscore name
            attr_desc = @@attribute_names[record.class.name][name.to_sym] rescue nil

            unless attr_desc.nil?
              type = attr_desc[:type]
              if attr_desc[:cardinality] == :many && !type.nil? && value.is_a?(Array)
                newValue = []
                value.each do |val|
                  if val.is_a?(Hash)
                    newValue << instantiate_record_from_json(type.to_s.constantize, val)
                  else
                    newValue << val
                  end
                end
                value = newValue
              elsif attr_desc[:cardinality] == :one && !type.nil? && value.is_a?(Hash)
                value = instantiate_record_from_json(type, value)
              end
            end #end unless attr_desc.nil? or data_elem.blank?

            record.send("#{Utils.underscore name}=", value )
          end #end data.each

          record
        end
        
        def attribute(name)
          self.send('attr_accessor', name.to_sym)

          self.instance_variable_set('@json_attributes', []) unless self.instance_variable_get('@json_attributes')
          self.instance_variable_get('@json_attributes') << name.to_s

          attributes = self.instance_variable_get('@json_attributes')

          (
           class << self;
             self
           end).send(:define_method, :json_attributes) do
             attributes
           end
         end

         def has_many(attr_name, type = nil)
           send("attr_accessor", attr_name.to_sym)

           #add it to attribute_names
           @@attribute_names[self.name] = {} unless @@attribute_names[self.name]
           @@attribute_names[self.name][attr_name.to_sym] = {:type => type,  :cardinality => :many }
         end

         def has_one(attr_name, type = nil)
           send("attr_accessor", attr_name.to_sym)
           
           #add it to attribute_names
           @@attribute_names[self.name] = {} unless @@attribute_names[self.name]
           @@attribute_names[self.name][attr_name.to_sym] = { :type => type, :cardinality => :one }
         end

       end #end self methods

       # Set on create call
       attr_accessor :uri

       def to_hash
         json_hash = {}
         self.class.json_attributes.each do |name|
           value = self.send(name)
           if value
             json_hash[Utils.camelize name, :lower] = value.is_a?(Resource) ? value.to_hash : value
           end
         end
         json_hash
       end

       def to_json
         to_hash.to_json
       end

       def refresh(clazz=self.class)
         if @uri
           self.class.get @uri, {}, {}, clazz
         else
           self
         end
       end

     end
   end
 end
