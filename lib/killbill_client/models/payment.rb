module KillBillClient
  module Model
    class Payment < PaymentAttributes
      KILLBILL_API_PAYMENTS_PREFIX = "#{KILLBILL_API_PREFIX}/payments"

      has_many :refunds, KillBillClient::Model::Refund
      has_many :chargebacks, KillBillClient::Model::Chargeback
      has_many :audit_logs, KillBillClient::Model::AuditLog

      create_alias :bundle_keys, :external_bundle_keys

      class << self
        def find_by_id(payment_id, with_refunds_and_chargebacks = false, options = {})
          get "#{KILLBILL_API_PAYMENTS_PREFIX}/#{payment_id}",
              {
                  :withRefundsAndChargebacks => with_refunds_and_chargebacks
              },
              options
        end

        def find_all_by_invoice_id(invoice_id, with_refunds_and_chargebacks = false, options = {})
          get "#{Invoice::KILLBILL_API_INVOICES_PREFIX}/#{invoice_id}/payments",
              {
                  :withRefundsAndChargebacks => with_refunds_and_chargebacks
              },
              options
        end

        def find_in_batches(offset = 0, limit = 100, options = {})
          get "#{KILLBILL_API_PAYMENTS_PREFIX}/#{Resource::KILLBILL_API_PAGINATION_PREFIX}",
              {
                  :offset => offset,
                  :limit => limit
              },
              options
        end

        def find_in_batches_by_search_key(search_key, offset = 0, limit = 100, options = {})
          get "#{KILLBILL_API_PAYMENTS_PREFIX}/search/#{search_key}",
              {
                  :offset => offset,
                  :limit => limit
              },
              options
        end
      end

      def create(external_payment = false, user = nil, reason = nil, comment = nil, options = {})
        # Nothing to return (nil)
        self.class.post "#{Account::KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/payments",
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
