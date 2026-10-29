require 'spec_helper'

describe KillBillClient::Model::RoleDefinition do

  def json_response(body)
    response = Net::HTTPOK.new('1.1', '200', 'OK')
    response['Content-Type'] = 'application/json'
    response.instance_variable_set(:@read, true)
    response.instance_variable_set(:@body, body)
    response
  end

  describe '.find_all' do
    it 'lists the role definitions' do
      body = [{'role' => 'admin', 'permissions' => ['account:create', 'invoice:view']},
              {'role' => 'finance', 'permissions' => ['payment:view']}].to_json

      expect(KillBillClient::API).to receive(:get)
                                       .with('/1.0/kb/security/roles', {}, {:api_key => 'key'})
                                       .and_return(json_response(body))

      roles = KillBillClient::Model::RoleDefinition.find_all({:api_key => 'key'})

      expect(roles.map(&:role)).to eq(%w(admin finance))
      expect(roles.first).to be_a(KillBillClient::Model::RoleDefinition)
      expect(roles.first.permissions).to eq(['account:create', 'invoice:view'])
      expect(roles.last.permissions).to eq(['payment:view'])
    end

    it 'returns an empty list when there are no role definitions' do
      allow(KillBillClient::API).to receive(:get).and_return(json_response('[]'))

      expect(KillBillClient::Model::RoleDefinition.find_all).to be_empty
    end
  end
end
