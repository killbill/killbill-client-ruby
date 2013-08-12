module KillBillClient
  module Model
    class PaymentMethod < PaymentMethodAttributes
      KILLBILL_API_PAYMENT_METHODS_PREFIX = "#{KILLBILL_API_PREFIX}/paymentMethods"

      class << self
        def find_by_id(payment_method_id, with_plugin_info = false)
          get "#{KILLBILL_API_PAYMENT_METHODS_PREFIX}/#{payment_method_id}",
              {
                  :withPluginInfo => with_plugin_info
              }
        end

        def find_all_by_account_id(account_id, with_plugin_info = false)
          get "#{Account::KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/paymentMethods",
              {
                  :withPluginInfo => with_plugin_info
              }
        end

        def find_all_by_search_key(search_key, with_plugin_info = false)
          get "#{KILLBILL_API_PAYMENT_METHODS_PREFIX}/search/#{search_key}",
              {
                  :withPluginInfo => with_plugin_info
              }
        end

        def set_default(payment_method_id, account_id, user = nil, reason = nil, comment = nil)
          put "#{Account::KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/paymentMethods/#{payment_method_id}/setDefault",
              nil,
              {},
              {
                  :user => user,
                  :reason => reason,
                  :comment => comment,
              }
        end

        def destroy(payment_method_id, set_auto_pay_off = false, user = nil, reason = nil, comment = nil)
          delete "#{KILLBILL_API_PAYMENT_METHODS_PREFIX}/#{payment_method_id}",
                 {
                     :deleteDefaultPmWithAutoPayOff => set_auto_pay_off
                 },
                 {
                     :user => user,
                     :reason => reason,
                     :comment => comment,
                 }
        end
      end

      def create(set_default = true, user = nil, reason = nil, comment = nil)
        created_pm = self.class.post "#{Account::KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/paymentMethods",
                                     to_json,
                                     {
                                         :isDefault => set_default
                                     },
                                     {
                                         :user => user,
                                         :reason => reason,
                                         :comment => comment,
                                     }
        created_pm.refresh
      end

      def destroy(set_auto_pay_off = false, user = nil, reason = nil, comment = nil)
        self.class.destroy(payment_method_id, set_auto_pay_off, user, reason, comment)
      end

      def plugin_info=(info)
        @plugin_info = PaymentMethodPluginDetailAttributes.new
        @plugin_info.properties = []
        return if info.nil?

        info.each { |k, v| @plugin_info.send("#{Utils.underscore k}=", v) unless k == 'properties' }

        if info['properties'].nil?
          # Convenience method to create properties to add a payment method
          info.each do |key, value|
            property = PaymentMethodProperties.new
            property.key = key
            property.value = value
            property.is_updatable = false
            @plugin_info.properties << property
          end
        else
          # De-serialization from JSON payload
          info['properties'].each do |property_json|
            property = PaymentMethodProperties.new
            property.key = property_json['key']
            property.value = property_json['value']
            property.is_updatable = property_json['isUpdatable']
            @plugin_info.properties << property
          end
        end
      end
    end
  end
end
