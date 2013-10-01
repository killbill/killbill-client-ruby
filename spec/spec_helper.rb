$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'bundler'
require 'killbill_client'

require 'logger'

require 'rspec'

KillBillClient.url = 'http://127.0.0.1:8080'
KillBillClient.username = "__YOUR_SERVER_USERNAME__"
KillBillClient.password = "__YOUR_SERVER_PASSWORD__"

RSpec.configure do |config|
  config.color_enabled = true
  config.tty = true
  config.formatter = 'documentation'
end

begin
  require 'securerandom'
  SecureRandom.uuid
rescue LoadError, NoMethodError
  # See http://jira.codehaus.org/browse/JRUBY-6176
  module SecureRandom
    def self.uuid
      ary = self.random_bytes(16).unpack("NnnnnN")
      ary[2] = (ary[2] & 0x0fff) | 0x4000
      ary[3] = (ary[3] & 0x3fff) | 0x8000
      "%08x-%04x-%04x-%04x-%04x%08x" % ary
    end unless respond_to?(:uuid)
  end
end
