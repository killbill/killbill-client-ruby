require 'spec_helper'

describe KillBillClient do

  it 'should be able to parse a url with http' do
    KillBillClient.url = "http://example.com:8080"
    KillBillClient::API.base_uri.scheme.should == "http"
    KillBillClient::API.base_uri.host.should == "example.com"
    KillBillClient::API.base_uri.port.should == 8080
  end

  it 'should be able to parse a url without http' do
    KillBillClient.url = "example.com:8080"
    KillBillClient::API.base_uri.scheme.should == "http"
    KillBillClient::API.base_uri.host.should == "example.com"
    KillBillClient::API.base_uri.port.should == 8080
  end
end
