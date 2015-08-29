require 'spec_helper'

describe KillBillClient::Model::Resource do
  class_var_name = '@@attribute_names'
  
  it 'should test has_one property' do
    #test account_timeline has one account
    #has_one :account, KillBillClient::Model::Account
    #expected "KillBillClient::Model::AccountTimeline"=>{:account=>{:type=>KillBillClient::Model::Account, :cardinality=>:one}, :payments=>{:type=>KillBillClient::Model::Payment, :cardinality=>:many}, :bundles=>{:type=>KillBillClient::Model::Bundle, :cardinality=>:many}, :invoices=>{:type=>KillBillClient::Model::Invoice, :cardinality=>:many}}
    test_var = KillBillClient::Model::AccountTimeline.class_variable_defined? class_var_name
    test_var.should_not be_false

    var = KillBillClient::Model::AccountTimeline.send(:class_variable_get, class_var_name)
    var.size.should > 0
    var.should have_key "KillBillClient::Model::AccountTimeline"
    var["KillBillClient::Model::AccountTimeline"].should have_key :account

    attr = var["KillBillClient::Model::AccountTimeline"][:account]

    attr.should have_key :type
    attr.should have_key :cardinality

    attr[:type].should == KillBillClient::Model::Account
    attr[:cardinality].should == :one #has one

    #should also be accessible by attr_accessors

    methods = KillBillClient::Model::AccountTimeline.instance_methods
    methods.map(&:to_sym).should include :account     # attr_reader
    methods.map(&:to_sym).should include :account= #attr_writer
  end

  it 'should test has_many property' do
    #test event has many audit_logs
    #has_many :audit_logs, KillBillClient::Model::AuditLog
    #expected {"KillBillClient::Model::SubscriptionEvent"=>{:audit_logs=>{:type=>KillBillClient::Model::AuditLog, :cardinality=>:many}}}

    test_var = KillBillClient::Model::EventSubscription.class_variable_defined? class_var_name
    test_var.should_not be_false

    var = KillBillClient::Model::EventSubscription.send(:class_variable_get, class_var_name)
    var.size.should > 0
    var.should have_key "KillBillClient::Model::Subscription"
    var["KillBillClient::Model::Subscription"].should have_key :events

    attr = var["KillBillClient::Model::Subscription"][:events]

    attr.should have_key :type
    attr.should have_key :cardinality

    attr[:type].should == KillBillClient::Model::EventSubscription
    attr[:cardinality].should == :many #has many

    #should also be accessible by attr_accessors

    methods = KillBillClient::Model::EventSubscription.instance_methods
    methods.map(&:to_sym).should include :audit_logs     # attr_reader
    methods.map(&:to_sym).should include :audit_logs= #attr_writer
  end

  it 'should create alias attr accessors' do
    KillBillClient::Model::EventSubscription.create_alias :alias_date, :requested_dt

    methods = KillBillClient::Model::EventSubscription.instance_methods
    methods.map(&:to_sym).should include :alias_date
    methods.map(&:to_sym).should include :alias_date=

    evt = KillBillClient::Model::EventSubscription.new
    evt.alias_date = "devaroop"
    evt.requested_dt.should == "devaroop"
    evt.alias_date.should == "devaroop"
  end
end
 
