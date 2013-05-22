require 'cgi'

module KillBillClient
  class API
    # The superclass to all errors that occur when making an API request.
    class ResponseError < Error
      attr_reader :request
      attr_reader :response

      def initialize(request, response)
        @request, @response = request, response
      end

      def code
        response.code.to_i if response and response.code
      end

      def to_s
        if description
          return CGI.unescapeHTML description
        end

        return super unless code
        '%d %s (%s %s)' % [
            code, http_error, request.method, API.base_uri + request.path
        ]
      end

      private

      def description
        @response.body.strip if @response.body
      end

      def http_error
        Utils.demodulize self.class.name.gsub(/([a-z])([A-Z])/, '\1 \2')
      end
    end

    # === 3xx Redirection
    #
    # Not an error, per se, but should result in one in the normal course of
    # API interaction.
    class Redirection < ResponseError
    end

    # === 304 Not Modified
    #
    # Raised when a request is made with an ETag.
    class NotModified < ResponseError
    end

    # === 4xx Client Error
    #
    # The superclass to all client errors (responses with status code 4xx).
    class ClientError < ResponseError
    end

    # === 400 Bad Request
    #
    # The request was invalid or could not be understood by the server.
    # Resubmitting the request will likely result in the same error.
    class BadRequest < ClientError
    end

    # === 401 Unauthorized
    #
    # The API key is missing or invalid for the given request.
    class Unauthorized < ClientError
    end

    # === 403 Forbidden
    #
    # The login is attempting to perform an action it does not have privileges
    # to access. The login credentials are correct.
    class Forbidden < ClientError
    end

    # === 404 Not Found
    #
    # The resource was not found. This may be returned if the given account
    # code or subscription plan does not exist. The response body will explain
    # which resource was not found.
    class NotFound < ClientError
    end

    # === 405 Method Not Allowed
    #
    # A method was attempted where it is not allowed.
    #
    # If this is raised, there may be a bug with the client library or with
    # the server. Please contact skillbilling-users@googlegroups.com or
    # {file a bug}[https://github.com/killbill/killbill-client-ruby/issues].
    class MethodNotAllowed < ClientError
    end

    # === 406 Not Acceptable
    #
    # The request content type was not acceptable.
    #
    # If this is raised, there may be a bug with the client library or with
    # the server. Please contact killbilling-users@googlegroups.com or
    # {file a bug}[https://github.com/killbill/killbill-client-ruby/issues].
    class NotAcceptable < ClientError
    end

    # === 415 Unsupported Media Type
    #
    # The request body was not recognized as XML.
    #
    # If this is raised, there may be a bug with the client library or with
    # the server. Please contact killbilling-users@googlegroups.com or
    # {file a bug}[https://github.com/killbill/killbill-client-ruby/issues].
    class UnsupportedMediaType < ClientError
    end

    # === 422 Unprocessable Entity
    #
    # Could not process a POST or PUT request because the request is invalid.
    # See the response body for more details.
    class UnprocessableEntity < ClientError
    end

    # === 5xx Server Error
    #
    # The superclass to all server errors (responses with status code 5xx).
    class ServerError < ResponseError
    end

    # === 500 Internal Server Error
    #
    # The server encountered an error while processing your request and failed.
    class InternalServerError < ServerError
    end

    # === 502 Gateway Error
    #
    # The load balancer or web server had trouble connecting to Killbill.
    # Please try the request again.
    class GatewayError < ServerError
    end

    # === 503 Service Unavailable
    #
    # The service is temporarily unavailable. Please try the request again.
    class ServiceUnavailable < ServerError
    end

    # Error mapping by status code.
    ERRORS = Hash.new { |hash, code|
      unless hash.key? code
        case code
          when 400...500 then
            ClientError
          when 500...600 then
            ServerError
          else
            ResponseError
        end
      end
    }.update(
        304 => NotModified,
        400 => BadRequest,
        401 => Unauthorized,
        403 => Forbidden,
        404 => NotFound,
        406 => NotAcceptable,
        415 => UnsupportedMediaType,
        422 => UnprocessableEntity,
        500 => InternalServerError,
        502 => GatewayError,
        503 => ServiceUnavailable
    ).freeze
  end
end
