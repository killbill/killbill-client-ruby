require 'spec_helper'

describe KillBillClient::Model do
  it 'should manipulate accounts' do
    external_key = Time.now.to_i.to_s

    account = KillBillClient::Model::Account.new
    account.name = 'KillBillClient'
    account.external_key = external_key
    account.email = 'kill@bill.com'
    account.currency = 'USD'
    account.time_zone = 'UTC'
    account.address1 = '5, ruby road'
    account.address2 = 'Apt 4'
    account.postal_code = 10293
    account.company = 'KillBill, Inc.'
    account.city = 'SnakeCase'
    account.state = 'Awesome'
    account.country = 'LalaLand'
    account.locale = 'FR_fr'
    account.is_notified_for_invoices = false
    account.account_id.should be_nil

    # Create and verify the account
    account = account.create('KillBill Spec test')
    account.external_key.should == external_key
    account.account_id.should_not be_nil

    # Try to retrieve it
    account = KillBillClient::Model::Account.find_by_id account.account_id
    account.external_key.should == external_key
    account.payment_method_id.should be_nil

    # Add a payment method
    pm = KillBillClient::Model::PaymentMethod.new
    pm.account_id = account.account_id
    pm.plugin_name = '__EXTERNAL_PAYMENT__'
    pm.plugin_info = {}
    pm.payment_method_id.should be_nil

    pm = pm.create(true, 'KillBill Spec test')
    pm.payment_method_id.should_not be_nil

    # Try to retrieve it
    pm = KillBillClient::Model::PaymentMethod.find_by_id pm.payment_method_id, true
    pm.account_id.should == account.account_id

    account = KillBillClient::Model::Account.find_by_id account.account_id
    account.payment_method_id.should == pm.payment_method_id

    pms = KillBillClient::Model::PaymentMethod.find_all_by_account_id account.account_id
    pms.size.should == 1
    pms[0].payment_method_id.should == pm.payment_method_id

    pm.destroy(true, 'KillBill Spec test')

    account = KillBillClient::Model::Account.find_by_id account.account_id
    account.payment_method_id.should be_nil
  end
end
