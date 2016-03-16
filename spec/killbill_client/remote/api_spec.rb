require 'spec_helper'

describe KillBillClient::API do
  it 'should get all tag definitions', :integration => true  do
    response = KillBillClient::API.get '/1.0/kb/tagDefinitions'
    expect(response.code.to_i).to eq(200)
    tag_definitions = KillBillClient::Model::Resource.from_response KillBillClient::Model::TagDefinition, response
    expect(tag_definitions.size).to be > 1
  end
end
