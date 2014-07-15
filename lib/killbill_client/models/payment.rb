module KillBillClient
  module Model
    class Payment < PaymentAttributes
      KILLBILL_API_PAYMENTS_PREFIX = "#{KILLBILL_API_PREFIX}/payments"

      has_many :transactions, KillBillClient::Model::Transaction
      has_many :audit_logs, KillBillClient::Model::AuditLog

      class << self
        def find_by_id(payment_id, options = {})
          get "#{KILLBILL_API_PAYMENTS_PREFIX}/#{payment_id}",
              {},
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

      # STEPH should that live in account resource?
      # PIERRE Bad name really - maybe it should be Invoice.pay_all?
      def create(external_payment = false, payment_amount = nil, user = nil, reason = nil, comment = nil, options = {})
        # Nothing to return (nil)
        self.class.post "#{Account::KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/invoicePayments",
                        {},
                        {
                            :externalPayment => external_payment,
                            :paymentAmount => payment_amount
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
