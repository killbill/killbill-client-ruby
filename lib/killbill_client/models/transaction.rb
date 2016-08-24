require 'killbill_client/api/errors'

module KillBillClient
  module Model
    class Transaction < PaymentTransactionAttributes

      has_many :properties, KillBillClient::Model::PluginPropertyAttributes
      has_many :audit_logs, KillBillClient::Model::AuditLog

      def auth(account_id, payment_method_id = nil, user = nil, reason = nil, comment = nil, options = {})
        @transaction_type = 'AUTHORIZE'
        query_map = {}
        create_initial_transaction("#{Account::KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/payments", query_map, payment_method_id, user, reason, comment, options)
      end

      def purchase(account_id, payment_method_id = nil, user = nil, reason = nil, comment = nil, options = {})
        @transaction_type = 'PURCHASE'
        query_map = {}
        create_initial_transaction("#{Account::KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/payments", query_map, payment_method_id, user, reason, comment, options)
      end

      def credit(account_id, payment_method_id = nil, user = nil, reason = nil, comment = nil, options = {})
        @transaction_type = 'CREDIT'
        query_map = {}
        create_initial_transaction("#{Account::KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/payments", query_map, payment_method_id, user, reason, comment, options)
      end

      def auth_by_external_key(account_external_key, payment_method_id = nil, user = nil, reason = nil, comment = nil, options = {})
        @transaction_type = 'AUTHORIZE'
        query_map = {:externalKey => account_external_key}
        create_initial_transaction("#{Account::KILLBILL_API_ACCOUNTS_PREFIX}/payments", query_map, payment_method_id, user, reason, comment, options)
      end

      def purchase_by_external_key(account_external_key, payment_method_id = nil, user = nil, reason = nil, comment = nil, options = {})
        @transaction_type = 'PURCHASE'
        query_map = {:externalKey => account_external_key}
        create_initial_transaction("#{Account::KILLBILL_API_ACCOUNTS_PREFIX}/payments", query_map, payment_method_id, user, reason, comment, options)
      end

      def credit_by_external_key(account_external_key, payment_method_id = nil, user = nil, reason = nil, comment = nil, options = {})
        @transaction_type = 'CREDIT'
        query_map = {:externalKey => account_external_key}
        create_initial_transaction("#{Account::KILLBILL_API_ACCOUNTS_PREFIX}/payments", query_map, payment_method_id, user, reason, comment, options)
      end

      def complete(user = nil, reason = nil, comment = nil, options = {})
        complete_initial_transaction(user, reason, comment, options)
      end

      def complete_auth(user = nil, reason = nil, comment = nil, options = {})
        @transaction_type = 'AUTHORIZE'
        complete_initial_transaction(user, reason, comment, options)
      end

      def complete_purchase(user = nil, reason = nil, comment = nil, options = {})
        @transaction_type = 'PURCHASE'
        complete_initial_transaction(user, reason, comment, options)
      end

      def complete_credit(user = nil, reason = nil, comment = nil, options = {})
        @transaction_type = 'CREDIT'
        complete_initial_transaction(user, reason, comment, options)
      end

      def capture(user = nil, reason = nil, comment = nil, options = {})
        created_transaction = with_payment_failure_handling do
          self.class.post "#{follow_up_path(payment_id)}",
                          to_json,
                          {},
                          {
                              :user    => user,
                              :reason  => reason,
                              :comment => comment,
                          }.merge(options)
        end
        created_transaction.refresh(options, Payment)
      end

      def refund(user = nil, reason = nil, comment = nil, options = {})
        created_transaction = with_payment_failure_handling do
          self.class.post "#{follow_up_path(payment_id)}/refunds",
                          to_json,
                          {},
                          {
                              :user    => user,
                              :reason  => reason,
                              :comment => comment,
                          }.merge(options)
        end
        created_transaction.refresh(options, Payment)
      end

      def void(user = nil, reason = nil, comment = nil, options = {})
        created_transaction = with_payment_failure_handling do
          self.class.delete "#{follow_up_path(payment_id)}",
                            to_json,
                            {},
                            {
                                :user    => user,
                                :reason  => reason,
                                :comment => comment,
                            }.merge(options)
        end
        created_transaction.refresh(options, Payment)
      end

      def chargeback(user = nil, reason = nil, comment = nil, options = {})
        created_transaction = with_payment_failure_handling do
          self.class.post "#{follow_up_path(payment_id)}/chargebacks",
                          to_json,
                          {},
                          {
                              :user    => user,
                              :reason  => reason,
                              :comment => comment,
                          }.merge(options)
        end
        created_transaction.refresh(options, Payment)
      end


      def cancel_scheduled_payment(user = nil, reason = nil, comment = nil, options = {})

        uri = transaction_external_key ? "#{Payment::KILLBILL_API_PAYMENTS_PREFIX}/cancelScheduledPaymentTransaction" :
            "#{Payment::KILLBILL_API_PAYMENTS_PREFIX}/#{transaction_id}/cancelScheduledPaymentTransaction"

        query_map = {}
        query_map[:transactionExternalKey] = transaction_external_key if transaction_external_key
        self.class.delete uri,
                          {},
                          query_map,
                          {
                              :user    => user,
                              :reason  => reason,
                              :comment => comment,
                          }.merge(options)
      end

      private


      def follow_up_path(payment_id)
        path = Payment::KILLBILL_API_PAYMENTS_PREFIX
        path += "/#{payment_id}" unless payment_id.nil?
        path
      end

      def create_initial_transaction(path, query_map, payment_method_id, user, reason, comment, options)
        query_map[:paymentMethodId] = payment_method_id unless payment_method_id.nil?

        created_transaction = with_payment_failure_handling do
          self.class.post path,
                          to_json,
                          query_map,
                          {
                              :user => user,
                              :reason => reason,
                              :comment => comment
                          }.merge(options)
        end
        created_transaction.refresh(options, Payment)
      end

      def complete_initial_transaction(user, reason, comment, options)
        created_transaction = with_payment_failure_handling do
          self.class.put follow_up_path(payment_id),
                         to_json,
                         {},
                         {
                             :user => user,
                             :reason => reason,
                             :comment => comment
                         }.merge(options)
        end
        created_transaction.refresh(options, Payment)
      end

      private

      def with_payment_failure_handling
        begin
          created_transaction = yield
        rescue KillBillClient::API::ResponseError => error
          response = error.response
          if response.header['location']
            created_transaction = Transaction.new
            created_transaction.uri = response.header['location']
          else
            raise error
          end
        end

        created_transaction
      end
    end
  end
end
