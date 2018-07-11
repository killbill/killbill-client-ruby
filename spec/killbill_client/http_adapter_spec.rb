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
  let (:options) {{:read_timeout => 10000, :connection_timeout => 5000, :disable_ssl_verification => true}}

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
    expect(http_client.use_ssl?).to be false
    expect(http_client.verify_mode).to be_nil
  end

  it 'should set the correct parameters for http client' do
    http_adapter = DummyForHTTPAdapter.new
    http_client = http_adapter.send(:create_http_client, ssl_uri, options)
    expect(http_client.read_timeout).to eq(options[:read_timeout] / 1000)
    expect(http_client.open_timeout).to eq(options[:connection_timeout] / 1000)
    expect(http_client.use_ssl?).to be true
    expect(http_client.verify_mode).to eq(OpenSSL::SSL::VERIFY_NONE)
  end

  # See https://github.com/killbill/killbill-client-ruby/issues/69
  it 'should construct URIs' do
    http_adapter = DummyForHTTPAdapter.new
    uri = http_adapter.send(:build_uri, KillBillClient::Model::Account::KILLBILL_API_ACCOUNTS_PREFIX, options)
    expect(uri).to eq(URI.parse("#{KillBillClient::API.base_uri.to_s}/1.0/kb/accounts"))
  end
end

class DummyForHTTPAdapter
  include KillBillClient::API::Net::HTTPAdapter
end
