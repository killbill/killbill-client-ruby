module KillBillClient
  module Model
    class AccountTimeline < AccountTimelineAttributes

      has_one :account, KillBillClient::Model::Account
      has_many :payments, KillBillClient::Model::Payment
      has_many :bundles, KillBillClient::Model::Bundle
      has_many :invoices, KillBillClient::Model::Invoice

      class << self

        def find_by_account_id account_id, audit = "MINIMAL"
          get "#{Account::KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/timeline",
          {
            :audit => audit
          }
        end

      end #end static methods


    end #end AccountTimeline
  end#end Model
end#end KillBillClient
