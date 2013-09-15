module KillBillClient
  module Model
    class Payment < PaymentAttributes
      has_many :refunds, KillBillClient::Model::Refund
      has_many :chargebacks, KillBillClient::Model::Chargeback
      has_many :audit_logs, KillBillClient::Model::AuditLog

      create_alias :bundle_keys, :external_bundle_keys
    end
  end
end
