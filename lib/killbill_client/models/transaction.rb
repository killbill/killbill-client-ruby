module KillBillClient
  module Model
    class Transaction < PaymentTransactionAttributes

      has_many :audit_logs, KillBillClient::Model::AuditLog

      def auth(account_id, payment_method_id = nil, user = nil, reason = nil, comment = nil, options = {})
        query_map                   = {}
        query_map[:paymentMethodId] = payment_method_id unless payment_method_id.nil?

        @transaction_type   = 'AUTHORIZE'
        created_transaction = self.class.post "#{Account::KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/payments",
                                              to_json,
                                              query_map,
                                              {
                                                  :user    => user,
                                                  :reason  => reason,
                                                  :comment => comment,
                                              }.merge(options)
        created_transaction.refresh(options, Payment)
      end

      def purchase(account_id, payment_method_id = nil, user = nil, reason = nil, comment = nil, options = {})
        query_map                   = {}
        query_map[:paymentMethodId] = payment_method_id unless payment_method_id.nil?

        @transaction_type   = 'PURCHASE'
        created_transaction = self.class.post "#{Account::KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/payments",
                                              to_json,
                                              query_map,
                                              {
                                                  :user    => user,
                                                  :reason  => reason,
                                                  :comment => comment,
                                              }.merge(options)
        created_transaction.refresh(options, Payment)
      end

      def credit(account_id, payment_method_id = nil, user = nil, reason = nil, comment = nil, options = {})
        query_map                   = {}
        query_map[:paymentMethodId] = payment_method_id unless payment_method_id.nil?

        @transaction_type   = 'CREDIT'
        created_transaction = self.class.post "#{Account::KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/payments",
                                              to_json,
                                              query_map,
                                              {
                                                  :user    => user,
                                                  :reason  => reason,
                                                  :comment => comment,
                                              }.merge(options)
        created_transaction.refresh(options, Payment)
      end

      def capture(user = nil, reason = nil, comment = nil, options = {})
        created_transaction = self.class.post "#{Payment::KILLBILL_API_PAYMENTS_PREFIX}/#{payment_id}",
                                              to_json,
                                              {},
                                              {
                                                  :user    => user,
                                                  :reason  => reason,
                                                  :comment => comment,
                                              }.merge(options)
        created_transaction.refresh(options, Payment)
      end

      def refund(user = nil, reason = nil, comment = nil, options = {})
        created_transaction = self.class.post "#{Payment::KILLBILL_API_PAYMENTS_PREFIX}/#{payment_id}/refunds",
                                              to_json,
                                              {},
                                              {
                                                  :user    => user,
                                                  :reason  => reason,
                                                  :comment => comment,
                                              }.merge(options)
        created_transaction.refresh(options, Payment)
      end

      def void(user = nil, reason = nil, comment = nil, options = {})
        created_transaction = self.class.delete "#{Payment::KILLBILL_API_PAYMENTS_PREFIX}/#{payment_id}",
                                                to_json,
                                                {},
                                                {
                                                    :user    => user,
                                                    :reason  => reason,
                                                    :comment => comment,
                                                }.merge(options)
        created_transaction.refresh(options, Payment)
      end

      def chargeback(user = nil, reason = nil, comment = nil, options = {})
        created_transaction = self.class.post "#{Payment::KILLBILL_API_PAYMENTS_PREFIX}/#{payment_id}/chargebacks",
                                              to_json,
                                              {},
                                              {
                                                  :user    => user,
                                                  :reason  => reason,
                                                  :comment => comment,
                                              }.merge(options)
        created_transaction.refresh(options, Payment)
      end
    end
  end
end
