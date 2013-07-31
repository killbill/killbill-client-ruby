module KillBillClient
  module Model
    class Event < SubscriptionReadEventAttributes
      has_many :audit_logs, KillBillClient::Model::AuditLog
      
    end
  end
end
