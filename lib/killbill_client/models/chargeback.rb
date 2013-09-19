module KillBillClient
  module Model
    class Chargeback < ChargebackAttributes
      has_many :audit_logs, KillBillClient::Model::AuditLog

        KILLBILL_API_CHARGEBACKS_PREFIX = "#{KILLBILL_API_PREFIX}/chargebacks"
=begin

        Missing id in the Kill Bill server Refund resource

        class << self
          def find_by_id(account_id, with_balance = false, with_balance_and_cba = false, options = {})
            get "#{KILLBILL_API_CHARGEBACKS_PREFIX}/#{account_id}",
                {
                    :accountWithBalance => with_balance,
                    :accountWithBalanceAndCBA => with_balance_and_cba
                },
                options
          end
        end
=end
        def create(user = nil, reason = nil, comment = nil, options = {})
          created_chargeback = self.class.post KILLBILL_API_CHARGEBACKS_PREFIX,
                                            to_json,
                                            {},
                                            {
                                                :user => user,
                                                :reason => reason,
                                                :comment => comment,
                                            }.merge(options)
          created_chargeback.refresh(options)
        end

    end
  end
end
