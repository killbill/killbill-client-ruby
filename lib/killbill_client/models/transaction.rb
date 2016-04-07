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
        query_map = {
        }
        if options.include? :controlPluginNames
          query_map[:controlPluginName] = options.delete(:controlPluginNames)
        end

        created_transaction = self.class.post "#{follow_up_path(payment_id)}",
                                              to_json,
                                              query_map,
                                              {
                                                  :user    => user,
                                                  :reason  => reason,
                                                  :comment => comment,
                                              }.merge(options)
        created_transaction.refresh(options, Payment)
      end

      def refund(user = nil, reason = nil, comment = nil, options = {})

        query_map = {
        }
        if options.include? :controlPluginNames
          query_map[:controlPluginName] = options.delete(:controlPluginNames)
        end
        created_transaction = self.class.post "#{follow_up_path(payment_id)}/refunds",
                                              to_json,
                                              query_map,
                                              {
                                                  :user    => user,
                                                  :reason  => reason,
                                                  :comment => comment,
                                              }.merge(options)
        created_transaction.refresh(options, Payment)
      end

      def void(user = nil, reason = nil, comment = nil, options = {})

        query_map = {
        }
        if options.include? :controlPluginNames
          query_map[:controlPluginName] = options.delete(:controlPluginNames)
        end
        created_transaction = self.class.delete "#{follow_up_path(payment_id)}",
                                                to_json,
                                                query_map,
                                                {
                                                    :user    => user,
                                                    :reason  => reason,
                                                    :comment => comment,
                                                }.merge(options)
        created_transaction.refresh(options, Payment)
      end

      def chargeback(user = nil, reason = nil, comment = nil, options = {})

        query_map = {
        }
        if options.include? :controlPluginNames
          query_map[:controlPluginName] = options.delete(:controlPluginNames)
        end
        created_transaction = self.class.post "#{follow_up_path(payment_id)}/chargebacks",
                                              to_json,
                                              query_map,
                                              {
                                                  :user    => user,
                                                  :reason  => reason,
                                                  :comment => comment,
                                              }.merge(options)
        created_transaction.refresh(options, Payment)
      end

      private


      def follow_up_path(payment_id)
        path = Payment::KILLBILL_API_PAYMENTS_PREFIX
        path += "/#{payment_id}" unless payment_id.nil?
        path
      end

      def create_initial_transaction(path, query_map, payment_method_id, user, reason, comment, options)
        query_map[:paymentMethodId] = payment_method_id unless payment_method_id.nil?

        created_transaction = self.class.post path,
                                              to_json,
                                              query_map,
                                              {
                                                  :user => user,
                                                  :reason => reason,
                                                  :comment => comment,
                                              }.merge(options)
        created_transaction.refresh(options, Payment)
      end

      def complete_initial_transaction(user, reason, comment, options)
        created_transaction = self.class.put follow_up_path(payment_id),
                                             to_json,
                                             {},
                                             {
                                                 :user => user,
                                                 :reason => reason,
                                                 :comment => comment,
                                             }.merge(options)
        created_transaction.refresh(options, Payment)
      end
    end
  end
end
