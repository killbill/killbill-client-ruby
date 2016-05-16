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
        with_payment_required_handling do
          self.class.post "#{follow_up_path(payment_id)}",
                          to_json,
                          {},
                          {
                              :user    => user,
                              :reason  => reason,
                              :comment => comment,
                          }.merge(options)
        end
      end

      def refund(user = nil, reason = nil, comment = nil, options = {})
        with_payment_required_handling do
          self.class.post "#{follow_up_path(payment_id)}/refunds",
                          to_json,
                          {},
                          {
                              :user    => user,
                              :reason  => reason,
                              :comment => comment,
                          }.merge(options)
        end
      end

      def void(user = nil, reason = nil, comment = nil, options = {})
        with_payment_required_handling do
          self.class.delete "#{follow_up_path(payment_id)}",
                            to_json,
                            {},
                            {
                                :user    => user,
                                :reason  => reason,
                                :comment => comment,
                            }.merge(options)
        end
      end

      def chargeback(user = nil, reason = nil, comment = nil, options = {})
        with_payment_required_handling do
          self.class.post "#{follow_up_path(payment_id)}/chargebacks",
                          to_json,
                          {},
                          {
                              :user    => user,
                              :reason  => reason,
                              :comment => comment,
                          }.merge(options)
        end
      end

      private


      def follow_up_path(payment_id)
        path = Payment::KILLBILL_API_PAYMENTS_PREFIX
        path += "/#{payment_id}" unless payment_id.nil?
        path
      end

      def create_initial_transaction(path, query_map, payment_method_id, user, reason, comment, options)
        query_map[:paymentMethodId] = payment_method_id unless payment_method_id.nil?

        with_payment_required_handling do
          self.class.post path,
                          to_json,
                          query_map,
                          {
                              :user => user,
                              :reason => reason,
                              :comment => comment
                          }.merge(options)
        end
      end

      def complete_initial_transaction(user, reason, comment, options)
        with_payment_required_handling do
          self.class.put follow_up_path(payment_id),
                         to_json,
                         {},
                         {
                             :user => user,
                             :reason => reason,
                             :comment => comment
                         }.merge(options)
        end
      end

      private

      def with_payment_required_handling
        begin
          created_transaction = yield
        rescue KillBillClient::API::PaymentRequired => e
          created_transaction = self.class.from_response(e.response)
        end

        created_transaction.refresh(options, Payment)
      end
    end
  end
end
