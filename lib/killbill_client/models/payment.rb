module KillBillClient
  module Model
    class Payment < PaymentAttributes

      include KillBillClient::Model::CustomFieldHelper
      include KillBillClient::Model::TagHelper

      KILLBILL_API_PAYMENTS_PREFIX = "#{KILLBILL_API_PREFIX}/payments"

      has_many :transactions, KillBillClient::Model::Transaction
      has_many :payment_attempts, KillBillClient::Model::PaymentAttemptAttributes
      has_many :audit_logs, KillBillClient::Model::AuditLog

      has_custom_fields KILLBILL_API_PAYMENTS_PREFIX, :payment_id
      has_tags KILLBILL_API_PAYMENTS_PREFIX, :payment_id

      class << self
        def find_by_id(payment_id, with_plugin_info = false, with_attempts = false, options = {})
          get "#{KILLBILL_API_PAYMENTS_PREFIX}/#{payment_id}",
              {
                  :withAttempts => with_attempts,
                  :withPluginInfo => with_plugin_info
              },
              options
        end

        def find_by_external_key(external_key, with_plugin_info = false, with_attempts = false, options = {})
          get "#{KILLBILL_API_PAYMENTS_PREFIX}",
              {
                  :externalKey => external_key,
                  :withAttempts => with_attempts,
                  :withPluginInfo => with_plugin_info
              },
              options
        end

        def find_by_transaction_id(transaction_id, with_plugin_info = false, with_attempts = false, options = {})
          get "#{Transaction::KILLBILL_API_TRANSACTIONS_PREFIX}/#{transaction_id}",
              {
                  :withAttempts => with_attempts,
                  :withPluginInfo => with_plugin_info
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

        def chargerback_reversals_by_payment_id(payment_id, transaction_external_key, effective_date = nil, user = nil, reason = nil, comment = nil, options = {})
          payload                          = PaymentTransactionAttributes.new
          payload.transaction_external_key = transaction_external_key
          payload.effective_date           = effective_date
          post "#{KILLBILL_API_PAYMENTS_PREFIX}/#{payment_id}/chargebackReversals",
               payload.to_json,
               {},
               {
                   :user    => user,
                   :reason  => reason,
                   :comment => comment,
               }.merge(options)
        end

        def chargerback_by_external_key(payment_external_key, amount, currency, effective_date = nil, user = nil, reason = nil, comment = nil, options = {})
          payload                          = PaymentTransactionAttributes.new
          payload.payment_external_key     = payment_external_key
          payload.amount                   = amount
          payload.currency                 = currency
          payload.effective_date           = effective_date
          post "#{KILLBILL_API_PAYMENTS_PREFIX}/chargebacks",
               payload.to_json,
               {},
               {
                   :user    => user,
                   :reason  => reason,
                   :comment => comment,
               }.merge(options)
        end

        def refund_by_external_key(payment_external_key, amount,user = nil, reason = nil, comment = nil, options = {})
          payload                          = PaymentTransactionAttributes.new
          payload.payment_external_key     = payment_external_key
          payload.amount                   = amount
          post "#{KILLBILL_API_PAYMENTS_PREFIX}/refunds",
               payload.to_json,
               {},
               {
                   :user    => user,
                   :reason  => reason,
                   :comment => comment,
               }.merge(options)
        end
      end
    end
  end
end
