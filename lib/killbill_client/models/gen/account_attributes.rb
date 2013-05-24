module KillBillClient
  module Model
    class AccountAttributes < Resource
      attribute :account_id
      attribute :name
      attribute :first_name_length
      # TODO
      attribute :length
      attribute :external_key
      attribute :email
      attribute :bill_cycle_day_local
      attribute :currency
      attribute :payment_method_id
      attribute :time_zone
      attribute :address1
      attribute :address2
      attribute :postal_code
      attribute :company
      attribute :city
      attribute :state
      attribute :country
      attribute :locale
      attribute :phone
      attribute :is_migrated
      attribute :is_notified_for_invoices

      attribute :account_balance
    end
  end
end
