module KillBillClient
  module Model
    class SubscriptionNoEvents < SubscriptionAttributesNoEvents

      KILLBILL_API_SUBSCRIPTIONS_PREFIX = "#{KILLBILL_API_PREFIX}/subscriptions"

      KILLBILL_API_BUNDLE_PREFIX = "#{KILLBILL_API_PREFIX}/bundles"

      class << self
        def find_by_id(subscription_id, options = {})
          get "#{KILLBILL_API_SUBSCRIPTIONS_PREFIX}/#{subscription_id}",
              {},
              options
        end


        def find_by_bundle_id(bundle_id, options = {})
          get "#{KILLBILL_API_BUNDLE_PREFIX}/#{bundle_id}/subscriptions",
              {},
              options
        end
      end

    end
  end
end
