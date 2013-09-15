module KillBillClient
  module Model
    class Bundle < BundleAttributes
      has_many :subscriptions, KillBillClient::Model::Subscription
      has_many :audit_logs, KillBillClient::Model::AuditLog
    end
  end
end


