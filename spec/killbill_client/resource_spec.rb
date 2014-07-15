require 'spec_helper'

describe KillBillClient::Model::Resource do

  it 'should be able to be instantiated from hash' do
    payment1 = KillBillClient::Model::InvoicePayment.new
    payment1.account_id = '1234'
    payment1.target_invoice_id = '5678'
    payment1.purchased_amount = 12.42

    payment2 = KillBillClient::Model::InvoicePayment.new(payment1.to_hash)

    payment2.should == payment1
    payment2.account_id.should == '1234'
    payment2.target_invoice_id.should == '5678'
    payment2.purchased_amount.should == 12.42
  end
end
