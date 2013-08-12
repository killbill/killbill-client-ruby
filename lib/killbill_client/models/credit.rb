module KillBillClient
  module Model
    class Credit < CreditAttributes
      has_many :audit_logs, KillBillClient::Model::AuditLog      
    end
  end
end
