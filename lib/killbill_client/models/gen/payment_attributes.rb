module KillBillClient
  module Model
    class PaymentAttributes < Resource
      attribute :amount
      attribute :paid_amount
      attribute :account_id
      attribute :invoice_id
      attribute :payment_id
      attribute :payment_method_id
      attribute :requested_date
      attribute :effective_date
      attribute :retry_count
      attribute :currency
      attribute :status
      attribute :gateway_error_code
      attribute :gateway_error_msg
      attribute :ext_first_payment_id_ref
      attribute :ext_second_payment_id_ref
    end
  end
end
