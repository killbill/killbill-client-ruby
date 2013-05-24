module KillBillClient
  module Model
    class Account < AccountAttributes
      KILLBILL_API_ACCOUNTS_PREFIX = "#{KILLBILL_API_PREFIX}/accounts"

      class << self
        def find_by_id(account_id, with_balance = false, with_balance_and_cba = false)
          get "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}",
              {
                  :accountWithBalance => with_balance,
                  :accountWithBalanceAndCBA => with_balance_and_cba
              }
        end
      end

      def create(user = nil, reason = nil, comment = nil)
        created_account = self.class.post KILLBILL_API_ACCOUNTS_PREFIX,
                                          to_json,
                                          {},
                                          {
                                              :user => user,
                                              :reason => reason,
                                              :comment => comment,
                                          }
        created_account.refresh
      end

      def payments
        self.class.get "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/payments",
                       {},
                       {},
                       Payment
      end
    end
  end
end
