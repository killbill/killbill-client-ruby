module KillBillClient
  module Model
    class Payment < PaymentAttributes

      include KillBillClient::Model::CustomFieldHelper

      KILLBILL_API_PAYMENTS_PREFIX = "#{KILLBILL_API_PREFIX}/payments"

      has_many :transactions, KillBillClient::Model::Transaction
      has_many :audit_logs, KillBillClient::Model::AuditLog

      has_custom_fields KILLBILL_API_PAYMENTS_PREFIX, :payment_id

      class << self
        def find_by_id(payment_id, options = {})
          get "#{KILLBILL_API_PAYMENTS_PREFIX}/#{payment_id}",
              {},
              options
        end

        def find_by_external_key(external_key, options = {})
          get "#{KILLBILL_API_PAYMENTS_PREFIX}",
              {
                  :externalKey => external_key
              },
              options
        end

        def find_in_batches(offset = 0, limit = 100, options = {})
          get "#{KILLBILL_API_PAYMENTS_PREFIX}/#{Resource::KILLBILL_API_PAGINATION_PREFIX}",
              {
                  :offset => offset,
                  :limit  => limit
              },
              options
        end

        def find_in_batches_by_search_key(search_key, offset = 0, limit = 100, options = {})
          get "#{KILLBILL_API_PAYMENTS_PREFIX}/search/#{search_key}",
              {
                  :offset => offset,
                  :limit  => limit
              },
              options
        end
      end
    end
  end
end
