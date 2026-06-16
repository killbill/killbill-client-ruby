require 'spec_helper'

describe 'Raw JSON responses' do
  let(:raw_body) do
    '{"subscriptionId":"abc-123","externalKey":"key-1","accountId":"acct-1","state":"ACTIVE"}'
  end

  let(:fake_response) do
    response = double('Net::HTTPResponse')
    allow(response).to receive(:body).and_return(raw_body)
    response
  end

  describe KillBillClient::Model::Resource, '.raw_get' do
    it 'returns the raw response body without parsing it into a model' do
      uri = '/1.0/kb/some/endpoint'
      params = { :foo => 'bar' }
      options = { :api_key => 'k', :api_secret => 's' }

      expect(KillBillClient::API).to receive(:get).with(uri, params, options).and_return(fake_response)
      expect(KillBillClient::Model::Resource).not_to receive(:from_response)

      result = KillBillClient::Model::Resource.raw_get(uri, params, options)

      expect(result).to be_a(String)
      expect(result).to eq(raw_body)
    end

    it 'defaults params and options to empty hashes' do
      uri = '/1.0/kb/some/endpoint'

      expect(KillBillClient::API).to receive(:get).with(uri, {}, {}).and_return(fake_response)

      result = KillBillClient::Model::Resource.raw_get(uri)
      expect(result).to eq(raw_body)
    end

    it 'propagates KillBillClient::API errors instead of swallowing them' do
      uri = '/1.0/kb/missing'
      api_request = double('Net::HTTPRequest')
      api_response = double('Net::HTTPResponse',
                            :code => '404',
                            :body => '{"className":"NoSuchElementException"}')
      response_error = KillBillClient::API::ResponseError.new(api_request, api_response)

      expect(KillBillClient::API).to receive(:get).and_raise(response_error)

      expect { KillBillClient::Model::Resource.raw_get(uri) }
        .to raise_error(KillBillClient::API::ResponseError)
    end
  end

  describe KillBillClient::Model::Subscription, '.find_raw_by_id' do
    let(:subscription_id) { 'sub-1234' }
    let(:expected_uri) { "/1.0/kb/subscriptions/#{subscription_id}" }

    it 'GETs the subscription endpoint and returns the raw body' do
      options = { :api_key => 'k', :api_secret => 's' }

      expect(KillBillClient::API).to receive(:get)
        .with(expected_uri, { :audit => 'NONE' }, options)
        .and_return(fake_response)

      result = KillBillClient::Model::Subscription.find_raw_by_id(subscription_id, 'NONE', options)

      expect(result).to eq(raw_body)
    end

    it 'forwards the audit option to the API call' do
      expect(KillBillClient::API).to receive(:get)
        .with(expected_uri, { :audit => 'FULL' }, {})
        .and_return(fake_response)

      KillBillClient::Model::Subscription.find_raw_by_id(subscription_id, 'FULL')
    end

    it 'defaults the audit option to NONE' do
      expect(KillBillClient::API).to receive(:get)
        .with(expected_uri, { :audit => 'NONE' }, {})
        .and_return(fake_response)

      KillBillClient::Model::Subscription.find_raw_by_id(subscription_id)
    end

    it 'does not instantiate a Subscription model' do
      expect(KillBillClient::API).to receive(:get).and_return(fake_response)
      expect(KillBillClient::Model::Subscription).not_to receive(:from_response)
      expect(KillBillClient::Model::Subscription).not_to receive(:from_json)

      KillBillClient::Model::Subscription.find_raw_by_id(subscription_id)
    end
  end
end
