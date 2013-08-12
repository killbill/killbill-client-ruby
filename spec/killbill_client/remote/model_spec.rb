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

    # Add/Remove a tag
    account.tags.size.should == 0
    account.add_tag('TEST', 'KillBill Spec test')
    tags = account.tags
    tags.size.should == 1
    tags.first.tag_definition_name.should == 'TEST'
    account.remove_tag('TEST', 'KillBill Spec test')
    account.tags.size.should == 0

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

    # Check there is no payment associated with that account
    account.payments.size.should == 0

    # Add an external charge
    invoice_item = KillBillClient::Model::InvoiceItem.new
    invoice_item.account_id = account.account_id
    invoice_item.currency = account.currency
    invoice_item.amount = 123.98

    invoice = invoice_item.create 'KillBill Spec test'

    invoice.balance.should == 123.98

    # Check the account balance
    account = KillBillClient::Model::Account.find_by_id account.account_id, true
    account.account_balance.should == 123.98

    pm.destroy(true, 'KillBill Spec test')

    account = KillBillClient::Model::Account.find_by_id account.account_id
    account.payment_method_id.should be_nil
    
    #get its timeline
    timeline = KillBillClient::Model::AccountTimeline.find_by_account_id account.account_id
    
    timeline.account.external_key.should == external_key
    timeline.account.account_id.should_not be_nil
    
    timeline.invoices.should be_a_kind_of Array
    timeline.invoices.should_not be_empty #assuming there is invoices created before
    timeline.payments.should be_a_kind_of Array
    timeline.bundles.should be_a_kind_of Array

    #lets find the invoice by two methods
    invoice = timeline.invoices.first
    invoice_id = invoice.invoice_id
    invoice_number = invoice.invoice_number
    
    invoice_with_id = KillBillClient::Model::Invoice.find_by_id_or_number invoice_id
    invoice_with_number = KillBillClient::Model::Invoice.find_by_id_or_number invoice_number

    invoice_with_id.invoice_id.should == invoice_with_number.invoice_id
    invoice_with_id.invoice_number.should == invoice_with_number.invoice_number
    
  end

  it 'should manipulate tag definitions' do
    KillBillClient::Model::TagDefinition.all.size.should > 0
    KillBillClient::Model::TagDefinition.find_by_name('TEST').is_control_tag.should be_true

    tag_definition_name = Time.now.to_i.to_s
    KillBillClient::Model::TagDefinition.find_by_name(tag_definition_name).should be_nil

    tag_definition = KillBillClient::Model::TagDefinition.new
    tag_definition.name = tag_definition_name
    tag_definition.description = 'Tag for unit test'
    tag_definition.create('KillBill Spec test').id.should_not be_nil

    found_tag_definition = KillBillClient::Model::TagDefinition.find_by_name(tag_definition_name)
    found_tag_definition.name.should == tag_definition_name
    found_tag_definition.description.should == tag_definition.description
    found_tag_definition.is_control_tag.should be_false
  end
end
