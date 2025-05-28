require 'spec_helper'

describe KillBillClient::API do

  before do
    KillBillClient.url = nil
    KillBillClient.disable_ssl_verification = nil
    KillBillClient.read_timeout = nil
    KillBillClient.connection_timeout = nil
  end

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
    # The default value has changed from nil to 60 in 2.4
    #expect(http_client.open_timeout).to eq(60)
    expect(http_client.use_ssl?).to be false
    expect(http_client.verify_mode).to be_nil
  end

  it 'should set the global parameters for http client' do
    KillBillClient.url = 'https://example.com'
    KillBillClient.read_timeout = 123000
    KillBillClient.connection_timeout = 456000
    KillBillClient.disable_ssl_verification = true

    http_adapter = DummyForHTTPAdapter.new
    http_client = http_adapter.send(:create_http_client, ssl_uri, {})
    expect(http_client.read_timeout).to eq(123)
    expect(http_client.open_timeout).to eq(456)
    expect(http_client.use_ssl?).to be true
    expect(http_client.verify_mode).to eq(OpenSSL::SSL::VERIFY_NONE)
  end

  it 'should set the correct parameters for http client' do
    # These don't matter (overridden by options)
    KillBillClient.url = 'https://example.com'
    KillBillClient.read_timeout = 123000
    KillBillClient.connection_timeout = 456000
    KillBillClient.disable_ssl_verification = false

    http_adapter = DummyForHTTPAdapter.new
    http_client = http_adapter.send(:create_http_client, ssl_uri, options)
    expect(http_client.read_timeout).to eq(options[:read_timeout] / 1000)
    expect(http_client.open_timeout).to eq(options[:connection_timeout] / 1000)
    expect(http_client.use_ssl?).to be true
    expect(http_client.verify_mode).to eq(OpenSSL::SSL::VERIFY_NONE)
  end

  # See https://github.com/killbill/killbill-client-ruby/issues/69
  it 'should construct URIs' do
    KillBillClient.url = 'http://example.com:8080'

    http_adapter = DummyForHTTPAdapter.new
    uri = http_adapter.send(:build_uri, KillBillClient::Model::Account::KILLBILL_API_ACCOUNTS_PREFIX, options)
    expect(uri).to eq(URI.parse("#{KillBillClient::API.base_uri.to_s}/1.0/kb/accounts"))
  end

  describe '#build_uri' do
    let(:http_adapter) { DummyForHTTPAdapter.new }

    before do
      KillBillClient.url = 'http://example.com:8080'
    end

    context 'with basic relative URI' do
      it 'should combine base URI with relative URI' do
        relative_uri = '/1.0/kb/accounts'
        options = {}
        uri = http_adapter.send(:build_uri, relative_uri, options)
        expect(uri.to_s).to eq('http://example.com:8080/1.0/kb/accounts')
      end

      it 'should handle relative URI without leading slash' do
        relative_uri = '1.0/kb/accounts'
        options = {}
        uri = http_adapter.send(:build_uri, relative_uri, options)
        expect(uri.to_s).to eq('http://example.com:8080/1.0/kb/accounts')
      end
    end

    context 'with custom base_uri in options' do
      it 'should use custom base_uri from options' do
        relative_uri = '/1.0/kb/accounts'
        options = { base_uri: 'https://custom.example.com:9090' }
        uri = http_adapter.send(:build_uri, relative_uri, options)
        expect(uri.to_s).to eq('https://custom.example.com:9090/1.0/kb/accounts')
      end
    end

    context 'with absolute URI' do
      it 'should use absolute URI as-is' do
        relative_uri = 'https://absolute.example.com/api/test'
        options = {}
        uri = http_adapter.send(:build_uri, relative_uri, options)
        expect(uri.to_s).to eq('https://absolute.example.com/api/test')
      end
    end

    context 'with path encoding' do
      it 'should handle properly encoded URIs (with double encoding)' do
        relative_uri = '/1.0/kb/accounts/my%20account%20with%20spaces'
        options = {}
        uri = http_adapter.send(:build_uri, relative_uri, options)
        expect(uri.to_s).to eq('http://example.com:8080/%2F1.0%2Fkb%2Faccounts%2Fmy%2520account%2520with%2520spaces')
      end

      it 'should not encode safe characters in path' do
        relative_uri = '/1.0/kb/accounts/abc-1234'
        options = {}
        uri = http_adapter.send(:build_uri, relative_uri, options)
        expect(uri.to_s).to eq('http://example.com:8080/1.0/kb/accounts/abc-1234')
      end

      it 'should handle properly encoded URI with query string (with double encoding)' do
        relative_uri = '/1.0/kb/accounts/my%20account?search=test%20value'
        options = {}
        uri = http_adapter.send(:build_uri, relative_uri, options)
        expect(uri.to_s).to eq('http://example.com:8080/%2F1.0%2Fkb%2Faccounts%2Fmy%2520account?search=test%20value')
      end
    end

    context 'with query parameters in options' do
      it 'should add simple query parameters' do
        relative_uri = '/1.0/kb/accounts'
        options = { params: { accountId: '123', limit: 10 } }
        uri = http_adapter.send(:build_uri, relative_uri, options)
        expect(uri.query).to include('accountId=123')
        expect(uri.query).to include('limit=10')
      end

      it 'should handle array parameters' do
        relative_uri = '/1.0/kb/accounts'
        options = { params: { tags: ['premium', 'business'] } }
        uri = http_adapter.send(:build_uri, relative_uri, options)
        expect(uri.query).to include('tags=premium')
        expect(uri.query).to include('tags=business')
      end

      it 'should merge with existing query string in relative URI' do
        relative_uri = '/1.0/kb/accounts?existing=value'
        options = { params: { new: 'param' } }
        uri = http_adapter.send(:build_uri, relative_uri, options)
        expect(uri.query).to include('existing=value')
        expect(uri.query).to include('new=param')
      end

      it 'should handle empty params hash' do
        relative_uri = '/1.0/kb/accounts'
        options = { params: {} }
        uri = http_adapter.send(:build_uri, relative_uri, options)
        expect(uri.query).to be_nil
      end

      it 'should encode special characters in query parameters' do
        relative_uri = '/1.0/kb/accounts'
        options = { params: { search: 'test & special chars' } }
        uri = http_adapter.send(:build_uri, relative_uri, options)
        expect(uri.query).to include('search=test+%26+special+chars')
      end
    end

    context 'with plugin properties' do
      it 'should handle pluginProperty option' do
        contract_property = KillBillClient::Model::PluginPropertyAttributes.new
        contract_property.key = :contractId
        contract_property.value = 'test-123'
        relative_uri = '/1.0/kb/accounts'
        options = {
          params: {},
          pluginProperty: [contract_property]
        }
        uri = http_adapter.send(:build_uri, relative_uri, options)
        expect(uri.query).to include('pluginProperty=contractId%3Dtest-123')
      end
    end

    context 'with control plugin names' do
      it 'should handle controlPluginNames option' do
        relative_uri = '/1.0/kb/accounts'
        options = {
          params: {},
          controlPluginNames: ['plugin1', 'plugin2']
        }
        uri = http_adapter.send(:build_uri, relative_uri, options)
        expect(uri.query).to include('controlPluginName=plugin1')
        expect(uri.query).to include('controlPluginName=plugin2')
      end
    end
  end
end

class DummyForHTTPAdapter
  include KillBillClient::API::Net::HTTPAdapter
end
