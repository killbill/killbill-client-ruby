module KillBillClient
  module Model
    class Bundle < BundleAttributesSimple
      has_many :subscriptions, KillBillClient::Model::SubscriptionEvent
      has_many :audit_logs, KillBillClient::Model::AuditLog


    end
  end
end


