module KillBillClient
  module Model
    class Payment < PaymentAttributes
      KILLBILL_API_PAYMENTS_PREFIX = "#{KILLBILL_API_PREFIX}/payments"

      has_many :refunds, KillBillClient::Model::Refund
      has_many :chargebacks, KillBillClient::Model::Chargeback
      has_many :audit_logs, KillBillClient::Model::AuditLog

      create_alias :bundle_keys, :external_bundle_keys

      def create(external_payment = false, user = nil, reason = nil, comment = nil, options = {})
        # Nothing to return (nil)
        self.class.post "#{Invoice::KILLBILL_API_INVOICES_PREFIX}/payments",
                        to_json,
                        {
                            :externalPayment => external_payment
                        },
                        {
                            :user => user,
                            :reason => reason,
                            :comment => comment,
                        }.merge(options)
      end
    end
  end
end
