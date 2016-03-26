require 'spec_helper'

describe KillBillClient::API do

  it 'should send double-encoded uri' do
    plugin_properties = [
        {
            'key' => 'contractId',
            'value' => "test"
        },
        {
            'key'   => 'ledgerDetails',
            'value' =>  {
                'eventType' => 'void',
                'transactionType' => 'ubergateway',
                'contractType' => 'as_line_item'
            }.to_json
        }
    ].map{|hash| KVPair.from_hash(hash)}
    options = {
        :params => {:controlPluginName => "killbill-gtg"},
        :pluginProperty => plugin_properties
    }
    http_adapter = DummyForHTTPAdapter.new
    uri = http_adapter.send(:encode_params, options)
    (uri == expected_uri).should be_true
  end

  def expected_uri
    '?controlPluginName=killbill-gtg&pluginProperty=contractId%3Dtest&pluginProperty=ledgerDetails%3D%257B%2522eventType%2522%253A%2522void%2522%252C%2522transactionType%2522%253A%2522ubergateway%2522%252C%2522contractType%2522%253A%2522as_line_item%2522%257D'
  end
end

class KVPair
  attr_accessor :key, :value
  def self.from_hash(hash)
    KVPair.new.tap do |p|
      p.key = hash['key']
      p.value = hash['value']
    end
  end
end

class DummyForHTTPAdapter
  include KillBillClient::API::Net::HTTPAdapter
end