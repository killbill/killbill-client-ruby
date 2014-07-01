module KillBillClient
  module Model
    class InvoicePayment < InvoicePaymentAttributes
      KILLBILL_API_INVOICE_PAYMENTS_PREFIX = "#{KILLBILL_API_PREFIX}/invoicePayments"

      has_many :transactions, KillBillClient::Model::DirectTransactionAttributes

      class << self
        def find_all_by_payment_id(payment_id, with_plugin_info = false, options = {})
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
    end
  end
end
