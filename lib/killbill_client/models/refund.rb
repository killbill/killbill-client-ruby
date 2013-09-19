module KillBillClient
  module Model
    class Refund < RefundAttributes
      KILLBILL_API_REFUNDS_PREFIX = "#{KILLBILL_API_PREFIX}/refunds"

      has_many :audit_logs, KillBillClient::Model::AuditLog
      has_many :adjustments, KillBillClient::Model::InvoiceItem

      class << self
        
        def find_by_id refund_id, options = {}
          get "#{KILLBILL_API_REFUNDS_PREFIX}/#{refund_id}",
          {},
          options
        end

        def find_all_by_payment_id payment_id, options = {}
          get "#{Payment::KILLBILL_API_PAYMENTS_PREFIX}/#{payment_id}/refunds",
          {},
          options
        end

      end #end class methods

      def create(user = nil, reason = nil, comment = nil, options = {})
        created_refund = self.class.post "#{Payment::KILLBILL_API_PAYMENTS_PREFIX}/#{@payment_id}/refunds",
        to_json,
        {},
        {
          :user => user,
          :reason => reason,
          :comment => comment,
        }.merge(options)

        created_refund.refresh(options)
      end

    end
  end
end
