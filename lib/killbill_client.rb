#
# Copyright 2011-2013 Ning, Inc.
#
# Ning licenses this file to you under the Apache License, version 2.0
# (the "License"); you may not use this file except in compliance with the
# License.  You may obtain a copy of the License at:
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
# License for the specific language governing permissions and limitations
# under the License.

# KillBillClient is a Ruby client for Kill Bill's REST API.
module KillBillClient
  # The exception class from which all KillBill exceptions inherit.
  class Error < StandardError
    def set_message(message)
      @message = message
    end

    # @return [String]
    def to_s
      defined? @message and @message or super
    end
  end

  # This exception is raised if KillBill has not been configured.
  class ConfigurationError < Error
  end

  class << self
    # @return [String] A host.
    def url
      defined? @url and @url or raise(
          ConfigurationError, 'KillBillClient.url not configured'
      )
    end

    attr_writer :url

    # Tenant key/password. Optional.
    attr_accessor :api_key
    attr_accessor :api_secret

    # @return [String, nil] A default currency.
    def default_currency
      return @default_currency if defined? @default_currency
      @default_currency = 'USD'
    end

    attr_writer :default_currency

    # Assigns a logger to log requests/responses and more.
    #
    # @return [Logger, nil]
    # @example
    #   require 'logger'
    #   KillBill.logger = Logger.new STDOUT
    # @example Rails applications automatically log to the Rails log:
    #   KillBill.logger = Rails.logger
    # @example Turn off logging entirely:
    #   KillBill.logger = nil # Or KillBill.logger = Logger.new nil
    attr_accessor :logger

    # Convenience logging method includes a Logger#progname dynamically.
    # @return [true, nil]
    def log(level, message)
      logger.send(level, name) { message }
    end

    if RUBY_VERSION <= '1.9.0'
      def const_defined?(sym, inherit = false)
        raise ArgumentError, 'inherit must be false' if inherit
        super sym
      end

      def const_get(sym, inherit = false)
        raise ArgumentError, 'inherit must be false' if inherit
        super sym
      end
    end
  end

  require 'killbill_client/models/models'
  require 'killbill_client/api'
  require 'killbill_client/resource'
  require 'killbill_client/utils'
  require 'killbill_client/version'
end

require 'rails/killbill_client' if defined? Rails::Railtie
