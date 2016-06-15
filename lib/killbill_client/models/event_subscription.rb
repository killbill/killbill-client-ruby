module KillBillClient
  module Model
    class EventSubscription < EventSubscriptionAttributes
      has_many :audit_logs, KillBillClient::Model::AuditLog

      create_alias :effective_date, :effective_dt
    end
  end
end
