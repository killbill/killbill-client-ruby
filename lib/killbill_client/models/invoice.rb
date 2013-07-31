module KillBillClient
  module Model
    class Invoice < InvoiceAttributesSimple
      KILLBILL_API_INVOICES_PREFIX = "#{KILLBILL_API_PREFIX}/invoices"

      has_many :audit_logs, KillBillClient::Model::AuditLog
      has_many :items, KillBillClient::Model::InvoiceItem
      has_many :credits, KillBillClient::Model::Credit
      
      class << self

        def get_invoice(id_or_number, with_items = true)
          get "#{KILLBILL_API_INVOICES_PREFIX}/#{id_or_number}",
          {
            :withItems => with_items
          }
        end

      end
    end
  end
end
