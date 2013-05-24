module KillBillClient
  module Model
    class InvoiceItemAttributes < Resource
      attribute :account_id
      attribute :currency
      attribute :amount
      attribute :description
      attribute :credit_adj
      attribute :refund_adj
      attribute :invoice_id
      attribute :invoice_date
      attribute :target_date
      attribute :invoice_number
      attribute :balance
      attribute :audit_logs
    end
  end
end
