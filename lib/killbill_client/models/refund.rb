module KillBillClient
  module Model
    class Refund < RefundAttributes
      has_many :audit_logs, KillBillClient::Model::AuditLog
      has_many :adjustments, KillBillClient::Model::InvoiceItem
      
    end
  end
end
