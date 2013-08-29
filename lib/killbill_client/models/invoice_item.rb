module KillBillClient
  module Model
    class InvoiceItem < InvoiceItemAttributesSimple

      has_many :audit_logs, KillBillClient::Model::AuditLog

      def create(user = nil, reason = nil, comment = nil, options = {})
        created_invoice_item = self.class.post "#{Invoice::KILLBILL_API_INVOICES_PREFIX}/charges",
                                               to_json,
                                               {},
                                               {
                                                   :user => user,
                                                   :reason => reason,
                                                   :comment => comment,
                                               }.merge(options)
        created_invoice_item.refresh(options, Invoice)
      end
    end
  end
end
