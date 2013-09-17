module KillBillClient
  module Model
    class Payment < PaymentAttributes
      KILLBILL_API_PAYMENTS_PREFIX = "#{KILLBILL_API_PREFIX}/payments"

      has_many :refunds, KillBillClient::Model::Refund
      has_many :chargebacks, KillBillClient::Model::Chargeback
      has_many :audit_logs, KillBillClient::Model::AuditLog

      create_alias :bundle_keys, :external_bundle_keys
    end
  end
end
