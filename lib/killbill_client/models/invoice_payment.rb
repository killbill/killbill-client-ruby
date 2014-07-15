module KillBillClient
  module Model
    class InvoicePayment < InvoicePaymentAttributes
      KILLBILL_API_INVOICE_PAYMENTS_PREFIX = "#{KILLBILL_API_PREFIX}/invoicePayments"

      has_many :transactions, KillBillClient::Model::Transaction
      has_many :audit_logs, KillBillClient::Model::AuditLog

      class << self
        def find_by_id(payment_id, with_plugin_info = false, options = {})
          get "#{KILLBILL_API_INVOICE_PAYMENTS_PREFIX}/#{payment_id}",
              {
                  :withPluginInfo => with_plugin_info
              },
              options
        end

        def refund(payment_id, amount, adjustments = nil, user = nil, reason = nil, comment = nil, options = {})
          payload             = InvoicePaymentTransactionAttributes.new
          payload.amount      = amount
          payload.is_adjusted = !adjustments.nil?
          payload.adjustments = adjustments

          invoice_payment = post "#{KILLBILL_API_INVOICE_PAYMENTS_PREFIX}/#{payment_id}/refunds",
                                 payload.to_json,
                                 {},
                                 {
                                     :user    => user,
                                     :reason  => reason,
                                     :comment => comment,
                                 }.merge(options)

          invoice_payment.refresh(options)
        end
      end

      def create(external_payment = false, user = nil, reason = nil, comment = nil, options = {})
        created_invoice_payment = self.class.post "#{Invoice::KILLBILL_API_INVOICES_PREFIX}/#{target_invoice_id}/payments",
                                                  to_json,
                                                  {
                                                      :externalPayment => external_payment
                                                  },
                                                  {
                                                      :user    => user,
                                                      :reason  => reason,
                                                      :comment => comment,
                                                  }.merge(options)
        created_invoice_payment.refresh(options)
      end
    end
  end
end
