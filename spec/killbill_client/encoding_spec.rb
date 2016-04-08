require 'spec_helper'

describe KillBillClient::API do
  let(:expected_query_params) {
    [
      [
          'controlPluginName=killbill-example-plugin',
          'pluginProperty=contractId%3Dtest',
          'pluginProperty=details%3D%257B%2522eventType%2522%253A%2522voidEvent%2522%252C%2522transactionType%2522%253A%2522void%2522%257D'
      ],
      [
          'controlPluginName=killbill-example-plugin',
          'pluginProperty=contractId%3Dtest',
          'pluginProperty=details%3D%257B%2522transactionType%2522%253A%2522void%2522%252C%2522eventType%2522%253A%2522voidEvent%2522%257D'
      ]
    ]
  }

  it 'should send double-encoded uri' do
    contract_property = KillBillClient::Model::PluginPropertyAttributes.new
    contract_property.key = 'contractId'
    contract_property.value = 'test'
    info_property = KillBillClient::Model::PluginPropertyAttributes.new
    info_property.key = 'details'
    info_property.value = {
        'eventType' => 'voidEvent',
        'transactionType' => 'void'
    }.to_json
    plugin_properties = [contract_property, info_property]
    options = {
        :params => {:controlPluginName => 'killbill-example-plugin'},
        :pluginProperty => plugin_properties
    }
    http_adapter = DummyForHTTPAdapter.new
    query_string = http_adapter.send(:encode_params, options)
    expect(query_string.chars.first).to eq('?')
    expect(expected_query_params).to include(query_string[1..-1].split('&').sort)
  end
end

class DummyForHTTPAdapter
  include KillBillClient::API::Net::HTTPAdapter
end
