require 'spec_helper'

describe KillBillClient::API do
  let(:expected_query_params) {
    [
        'controlPluginName=killbill-example-plugin',
        'pluginProperty=contractId%3Dtest'
    ]
  }

  let (:ssl_uri) {URI.parse 'https://killbill.io'}
  let (:uri) {URI.parse 'http://killbill.io'}
  let (:timeouts) {{:read_timeout => 10000, :connection_timeout => 5000}}

  it 'should send double-encoded uri' do
    contract_property = KillBillClient::Model::PluginPropertyAttributes.new
    contract_property.key = :contractId
    contract_property.value = 'test'
    info_property = KillBillClient::Model::PluginPropertyAttributes.new
    info_property.key = 'details'
    info_property_hash = {
        'eventType' => 'voidEvent',
        'transactionType' => 'void'
    }
    info_property.value = info_property_hash.to_json
    plugin_properties = [contract_property, info_property]
    options = {
        :params => {:controlPluginName => 'killbill-example-plugin'},
        :pluginProperty => plugin_properties
    }
    http_adapter = DummyForHTTPAdapter.new
    query_string = http_adapter.send(:encode_params, options)
    expect(query_string.chars.first).to eq('?')
    query_params = query_string[1..-1].split('&').sort
    expect(query_params.size).to eq(3)

    # check the first two query strings
    expect(query_params[0..1]).to eq(expected_query_params)

    # decode info_property to check if it is double encoded
    info_property_query = CGI.parse(query_params[2])
    expect(info_property_query.size).to eq(1)
    expect(info_property_query.keys.first).to eq('pluginProperty')
    expect(info_property_query['pluginProperty'].size).to eq(1)
    output_info_property = info_property_query['pluginProperty'].first.split('=')
    expect(output_info_property.size).to eq(2)
    expect(output_info_property[0]).to eq(info_property.key)
    # should match if we decode it
    expect(JSON.parse CGI.unescape(output_info_property[1])).to eq(info_property_hash)
    # also ensure the undecoded value is different so that it was indeed encocded twice
    expect(output_info_property[1]).not_to eq(CGI.unescape output_info_property[1])
  end

  it 'should use the default parameters for http client' do
    http_adapter = DummyForHTTPAdapter.new
    http_client = http_adapter.send(:create_http_client, uri)
    expect(http_client.read_timeout).to eq(60)
    expect(http_client.open_timeout).to be_nil
    expect(http_client.use_ssl?).to be false
  end

  it 'should set the correct parameters for http client' do
    http_adapter = DummyForHTTPAdapter.new
    http_client = http_adapter.send(:create_http_client, ssl_uri, timeouts)
    expect(http_client.read_timeout).to eq(timeouts[:read_timeout] / 1000)
    expect(http_client.open_timeout).to eq(timeouts[:connection_timeout] / 1000)
    expect(http_client.use_ssl?).to be true
  end

end

class DummyForHTTPAdapter
  include KillBillClient::API::Net::HTTPAdapter
end
