module KillBillClient
  module Model
    class Chargeback < ChargebackAttributes
      has_many :audit_logs, KillBillClient::Model::AuditLog

    end
  end
end
