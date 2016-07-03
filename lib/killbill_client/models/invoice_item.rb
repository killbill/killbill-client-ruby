module KillBillClient
  module Model
    class InvoiceItem < InvoiceItemAttributes

      has_many :audit_logs, KillBillClient::Model::AuditLog

      def create(auto_commit = false, user = nil, reason = nil, comment = nil, options = {})
        created_invoice_item = self.class.post "#{Invoice::KILLBILL_API_INVOICES_PREFIX}/charges/#{account_id}",
                                               [to_hash].to_json,
                                               {:autoCommit => auto_commit},
                                               {
                                                   :user    => user,
                                                   :reason  => reason,
                                                   :comment => comment,
                                               }.merge(options)
        created_invoice_item.first.refresh(options, Invoice)
      end

      # Adjust an invoice item
      #
      # Required: account_id, invoice_id, invoice_item_id
      # Optional: amount, currency
      def update(user = nil, reason = nil, comment = nil, options = {})
        adjusted_invoice_item = self.class.post "#{Invoice::KILLBILL_API_INVOICES_PREFIX}/#{invoice_id}",
                                                to_json,
                                                {},
                                                {
                                                    :user    => user,
                                                    :reason  => reason,
                                                    :comment => comment,
                                                }.merge(options)
        adjusted_invoice_item.refresh(options, Invoice)
      end

      # Delete CBA
      #
      # Required: invoice_id, invoice_item_id
      def delete(user = nil, reason = nil, comment = nil, options = {})
        self.class.delete "#{Invoice::KILLBILL_API_INVOICES_PREFIX}/#{invoice_id}/#{invoice_item_id}/cba",
                          to_json,
                          {
                              :accountId => account_id
                          },
                          {
                              :user    => user,
                              :reason  => reason,
                              :comment => comment,
                          }.merge(options)
      end
    end
  end
end
