require 'spec_helper'

describe KillBillClient::API do
  it 'should get all tag definitions' do
    response = KillBillClient::API.get 'tagDefinitions'
    response.code.to_i.should == 200
    tag_definitions = KillBillClient::Resource.from_response KillBillClient::Model::TagDefinition, response
    tag_definitions.size.should > 1
  end
end
