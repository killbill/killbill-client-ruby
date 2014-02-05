module KillBillClient
  module Model
    class Chargeback < ChargebackAttributes
      has_many :audit_logs, KillBillClient::Model::AuditLog

        KILLBILL_API_CHARGEBACKS_PREFIX = "#{KILLBILL_API_PREFIX}/chargebacks"

        class << self
          def find_by_id(chargeback_id, options = {})
            get "#{KILLBILL_API_CHARGEBACKS_PREFIX}/#{chargeback_id}",
                {},
                options
          end

          def find_all_by_payment_id(payment_id, options = {})
            get "#{Payment::KILLBILL_API_PAYMENTS_PREFIX}/#{payment_id}/chargebacks",
                {},
                options
          end
        end

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
