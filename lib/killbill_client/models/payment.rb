module KillBillClient
  module Model
    class Payment < PaymentAttributesSimple
      has_many :refunds, KillBillClient::Model::Refund
      has_many :chargebacks, KillBillClient::Model::Chargeback
      has_many :audit_logs, KillBillClient::Model::AuditLog

    end
  end
end
