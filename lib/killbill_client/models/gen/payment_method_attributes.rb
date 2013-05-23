module KillBillClient
  module Model
    class PaymentMethodAttributes < Resource
      attribute :payment_method_id
      attribute :account_id
      attribute :is_default
      attribute :plugin_name
      attribute :plugin_info
    end
  end
end

