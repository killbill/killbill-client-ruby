require 'json'

module KillBillClient
  class Resource
    # Instantiates a record from an HTTP response, setting the record's
    # response attribute in the process.
    #
    # @return [Resource]
    # @param resource_class [Resource]
    # @param response [Net::HTTPResponse]
    def self.from_response(resource_class, response)
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
    def self.from_json(resource_class, json)
      data = JSON.parse json
      if data.is_a? Enumerable
        records = []
        data.each do |data_element|
          records << instantiate_record_from_json(resource_class, data_element)
        end
        records
      else
        instantiate_record_from_json(resource_class, data)
      end
    end

    def self.instantiate_record_from_json(resource_class, data)
      record = resource_class.send :new
      data.each { |k, v| record.send("#{Utils.underscore k}=", v) }
      record
    end
  end
end
