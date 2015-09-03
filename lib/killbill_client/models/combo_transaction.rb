module KillBillClient
  module Model
    class ComboTransaction < ComboPaymentTransactionAttributes

      def auth(user = nil, reason = nil, comment = nil, options = {})
        @transaction.transaction_type = 'AUTHORIZE'

        combo_payment(user, reason, comment, options)
      end

      def purchase(user = nil, reason = nil, comment = nil, options = {})
        @transaction.transaction_type = 'PURCHASE'

        combo_payment(user, reason, comment, options)
      end

      def credit(user = nil, reason = nil, comment = nil, options = {})
        @transaction.transaction_type = 'CREDIT'

        combo_payment(user, reason, comment, options)
      end

      private

      def combo_payment(user, reason, comment, options)
        query_map = {
            :controlPluginName => options.delete(:controlPluginNames)
        }

        created_transaction = self.class.post "#{Payment::KILLBILL_API_PAYMENTS_PREFIX}/combo",
                                              to_json,
                                              query_map,
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
