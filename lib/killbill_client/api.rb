module KillBillClient
  # The API class handles all requests to the Kill Bill API. While most of its
  # functionality is leveraged by the Resource class, it can be used directly,
  # as well.
  #
  # Requests are made with methods named after the four main HTTP verbs
  # recognized by the Kill Bill API.
  #
  # @example
  #   KillBillClient::API.get 'accounts'             # => #<Net::HTTPOK ...>
  #   KillBillClient::API.post 'accounts', json_body  # => #<Net::HTTPCreated ...>
  #   KillBillClient::API.put 'accounts/1', json_body # => #<Net::HTTPOK ...>
  #   KillBillClient::API.delete 'accounts/1'        # => #<Net::HTTPNoContent ...>
  class API
    require 'killbill_client/api/errors'

    class << self
      # Additional HTTP headers sent with each API call
      # @return [Hash{String => String}]
      def headers
        @headers ||= {'Accept' => accept, 'User-Agent' => user_agent}
      end

      # @return [String, nil] Accept-Language header value
      def accept_language
        headers['Accept-Language']
      end

      # @param [String] language Accept-Language header value
      def accept_language=(language)
        headers['Accept-Language'] = language
      end

      # @return [Net::HTTPOK, Net::HTTPResponse]
      # @raise [ResponseError] With a non-2xx status code.
      def head(uri, params = {}, options = {})
        request :head, uri, {:params => params}.merge(options)
      end

      # @return [Net::HTTPOK, Net::HTTPResponse]
      # @raise [ResponseError] With a non-2xx status code.
      def get(uri, params = {}, options = {})
        request :get, uri, {:params => params}.merge(options)
      end

      # @return [Net::HTTPCreated, Net::HTTPResponse]
      # @raise [ResponseError] With a non-2xx status code.
      def post(uri, body = nil, options = {})
        request :post, uri, {:body => body.to_s}.merge(options)
      end

      # @return [Net::HTTPOK, Net::HTTPResponse]
      # @raise [ResponseError] With a non-2xx status code.
      def put(uri, body = nil, options = {})
        request :put, uri, {:body => body.to_s}.merge(options)
      end

      # @return [Net::HTTPNoContent, Net::HTTPResponse]
      # @raise [ResponseError] With a non-2xx status code.
      def delete(uri, options = {})
        request :delete, uri, options
      end

      # @return [URI::Generic]
      def base_uri
        URI.parse(KillBillClient.url) + '/1.0/kb/'
      end

      # @return [String]
      def user_agent
        "killbill/#{Version}; #{RUBY_DESCRIPTION}"
      end

      private

      def accept
        'application/json'
      end

      alias content_type accept
    end
  end
end

require 'killbill_client/api/net_http_adapter'
