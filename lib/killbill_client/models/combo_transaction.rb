module KillBillClient
  module Model
    class ComboTransaction < ComboPaymentTransactionAttributes

      def auth(user = nil, reason = nil, comment = nil, options = {}, refresh_options = nil)
        @transaction.transaction_type = 'AUTHORIZE'

        combo_payment(user, reason, comment, options, refresh_options)
      end

      def purchase(user = nil, reason = nil, comment = nil, options = {}, refresh_options = nil)
        @transaction.transaction_type = 'PURCHASE'

        combo_payment(user, reason, comment, options, refresh_options)
      end

      def credit(user = nil, reason = nil, comment = nil, options = {}, refresh_options = nil)
        @transaction.transaction_type = 'CREDIT'

        combo_payment(user, reason, comment, options, refresh_options)
      end

      private

      def combo_payment(user, reason, comment, options, refresh_options = nil)
        begin
          created_transaction = self.class.post "#{Payment::KILLBILL_API_PAYMENTS_PREFIX}/combo",
                                                to_json,
                                                {},
                                                {
                                                    :user => user,
                                                    :reason => reason,
                                                    :comment => comment,
                                                }.merge(options)
        rescue KillBillClient::API::ResponseError => error
          response = error.response
          if response.header['location']
            created_transaction = self.class.from_response(response)
          else
            raise error
          end
        end
        created_transaction.refresh(refresh_options || options, Payment)
      end
    end
  end
end
