require 'spec_helper'

describe KillBillClient::Model do

  it 'should send double-encoded uri', :integration => true  do
    Net::HTTP.any_instance.stub(:request) do |request, body|
      # skip the second get request during the combo call
      if request.method == 'POST'
        (request.path == expected_auth_path).should be_true
      end
      successful_auth_response
    end
    #make a fake auth
    kb_combo = KillBillClient::Model::ComboTransaction.new
    kb_combo.transaction = KillBillClient::Model::Transaction.new
    plugin_properties = [
        {
            'key' => 'contractId',
            'value' => "test"
        },
        {
            'key'   => 'ledgerDetails',
            'value' =>  {
                "eventType" => "void",
                "transactionType" => "ubergateway",
                "contractType" => "as_line_item"
            }.to_json
        }
    ].map{|hash| KVPair.from_hash(hash)}
    options = {:controlPluginNames => "killbill-gtg"}
    options.merge!({:pluginProperty => plugin_properties})
    kb_combo.auth("test", nil, nil, options)
  end

  def expected_auth_path
    '/1.0/kb/payments/combo?controlPluginName%3Dkillbill-gtg%26pluginProperty%3DcontractId%253Dtest%26pluginProperty%3DledgerDetails%253D%257B%2522eventType%2522%253A%2522void%2522%252C%2522transactionType%2522%253A%2522ubergateway%2522%252C%2522contractType%2522%253A%2522as_line_item%2522%257D'
  end

  def successful_auth_response
    response = Net::HTTPResponse.new(1.1, 201, "Created")
    {
      'Date' => 'Fri, 25 Mar 2016 06:32:31 GMT',
      'Set-Cookie' => 'JSESSIONID=859; Path=/; HttpOnly',
      'Set-Cookie' => 'rememberMe=deleteMe; Path=/; Max-Age=0; Expires=Thu, 24-Mar-2016 06:32:31 GMT',
      'Access-Control-Allow-Origin' => '*',
      'Access-Control-Allow-Methods' => 'GET, POST, DELETE, PUT, OPTIONS',
      'Access-Control-Allow-Headers' => 'Authorization,Content-Type,X-Killbill-ApiKey,X-Killbill-ApiSecret,X-Killbill-Comment,X-Killbill-CreatedBy,X-Killbill-Pagination-CurrentOffset,X-Killbill-Pagination-MaxNbRecords,X-Killbill-Pagination-NextOffset,X-Killbill-Pagination-NextPageUri,X-Killbill-Pagination-TotalNbRecords,X-Killbill-Reason',
      'Location' => 'http://127.0.0.1:8080/1.0/kb/payments/c9bfc26b-bf9c-4216-99f0-481126cebaa9/',
      'Content-Type' => 'application/json',
      'Transfer-Encoding' => 'chunked',
      'Server' => 'Jetty(9.2.10.v20150310)'
    }.each do |key, value|
      response.add_field key, value
    end
    response.stub(:body){successful_auth_body}
    response
  end

  def successful_auth_body
    '{"uri":"http://127.0.0.1:8080/1.0/kb/payments/c9bfc26b-bf9c-4216-99f0-481126cebaa9/"}'
  end
end

# copied from urbegateway to replicate the same scenario as gtg
class KVPair
  attr_accessor :key, :value
  def self.from_hash(hash)
    KVPair.new.tap do |p|
      p.key = hash['key']
      p.value = hash['value']
    end
  end
end