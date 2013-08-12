module KillBillClient
  module Model
    class Event < SubscriptionReadEventAttributes
      has_many :audit_logs, KillBillClient::Model::AuditLog

      create_alias :requested_date, :requested_dt
      create_alias :effective_date, :effective_dt

    end
  end
end
