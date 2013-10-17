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

    # Get its timeline
    timeline = KillBillClient::Model::AccountTimeline.find_by_account_id account.account_id

    timeline.account.external_key.should == external_key
    timeline.account.account_id.should_not be_nil

    timeline.invoices.should be_a_kind_of Array
    timeline.invoices.should_not be_empty
    timeline.payments.should be_a_kind_of Array
    timeline.bundles.should be_a_kind_of Array

    # Let's find the invoice by two methods
    invoice = timeline.invoices.first
    invoice_id = invoice.invoice_id
    invoice_number = invoice.invoice_number

    invoice_with_id = KillBillClient::Model::Invoice.find_by_id_or_number invoice_id
    invoice_with_number = KillBillClient::Model::Invoice.find_by_id_or_number invoice_number

    invoice_with_id.invoice_id.should == invoice_with_number.invoice_id
    invoice_with_id.invoice_number.should == invoice_with_number.invoice_number

    # Create an external payment
    payment = KillBillClient::Model::Payment.new
    payment.account_id = account.account_id
    payment.create true, 'KillBill Spec test'

    # Check the account balance
    account = KillBillClient::Model::Account.find_by_id account.account_id, true
    account.account_balance.should == 0

    # Verify the timeline
    timeline = KillBillClient::Model::AccountTimeline.find_by_account_id account.account_id
    timeline.payments.should_not be_empty
    payment = timeline.payments.first
    payment.refunds.should be_empty

    # Refund the payment (with item adjustment)
    invoice_item = KillBillClient::Model::Invoice.find_by_id_or_number(invoice_number, true).items.first
    refund = KillBillClient::Model::Refund.new
    refund.payment_id = payment.payment_id
    refund.amount = payment.amount
    refund.adjusted = true
    item = KillBillClient::Model::InvoiceItem.new
    item.invoice_item_id = invoice_item.invoice_item_id
    item.amount = invoice_item.amount
    refund.adjustments = [item]
    refund.create 'KillBill Spec test'

    # Verify the refund
    timeline = KillBillClient::Model::AccountTimeline.find_by_account_id account.account_id
    timeline.payments.should_not be_empty
    payment = timeline.payments.first
    payment.refunds.should_not be_empty
    payment.refunds.first.amount.should == invoice_item.amount

    # Create a credit for invoice
    new_credit = KillBillClient::Model::Credit.new
    new_credit.credit_amount = 10.1
    new_credit.invoice_id = invoice_id
    new_credit.effective_date = "2013-09-30"
    new_credit.account_id = account.account_id
    new_credit.create 'KillBill Spec test'

    # Verify the invoice item of the credit
    invoice = KillBillClient::Model::Invoice.find_by_id_or_number invoice_id
    invoice.items.should_not be_empty
    item = invoice.items.last
    item.invoice_id.should == invoice_id
    item.amount.should == 10.1
    item.account_id.should == account.account_id

    # Verify the credit
    account = KillBillClient::Model::Account.find_by_id account.account_id, true
    account.account_balance.should == -10.1

    # Create a subscription
    sub = KillBillClient::Model::Subscription.new
    sub.account_id = account.account_id
    sub.external_key = Time.now.to_i.to_s
    sub.product_name = 'Sports'
    sub.product_category = 'BASE'
    sub.billing_period = 'MONTHLY'
    sub.price_list = 'DEFAULT'
    sub = sub.create 'KillBill Spec test'

    # Verify we can retrieve it
    account.bundles.size.should == 1
    account.bundles[0].subscriptions.size.should == 1
    account.bundles[0].subscriptions[0].subscription_id.should == sub.subscription_id
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

  it 'should manipulate tenants' do
    api_key = Time.now.to_i.to_s
    api_secret = 'S4cr3333333t!!!!!!lolz'

    tenant = KillBillClient::Model::Tenant.new
    tenant.api_key = api_key
    tenant.api_secret = api_secret

    # Create and verify the tenant
    tenant = tenant.create('KillBill Spec test')
    tenant.api_key.should == api_key
    tenant.tenant_id.should_not be_nil

    # Try to retrieve it by id
    tenant = KillBillClient::Model::Tenant.find_by_id tenant.tenant_id
    tenant.api_key.should == api_key

    # Try to retrieve it by api key
    tenant = KillBillClient::Model::Tenant.find_by_api_key tenant.api_key
    tenant.api_key.should == api_key
  end

  #it 'should retrieve users permissions' do
  #  # Tough to verify as it depends on the Kill Bill configuration
  #  puts KillBillClient::Model::Security.find_permissions
  #  puts KillBillClient::Model::Security.find_permissions(:username => 'admin', :password => 'password')
  #end
end
