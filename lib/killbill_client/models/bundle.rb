module KillBillClient
  module Model
    class Bundle < BundleAttributesSimple
      has_many :subscriptions, KillBillClient::Model::Subscription
      has_many :audit_logs, KillBillClient::Model::AuditLog


    end
  end
end


