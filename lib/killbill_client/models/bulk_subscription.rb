module KillBillClient
  module Model
    class BulkSubscription < BulkBaseSubscriptionAndAddOnsAttributes

      include KillBillClient::Model::CustomFieldHelper

      KILLBILL_API_BULK_ENTITLEMENT_PREFIX = "#{KILLBILL_API_PREFIX}/subscriptions/createEntitlementsWithAddOns"

      has_many :base_entitlement_and_add_ons, KillBillClient::Model::SubscriptionAttributes

      class << self

        def create_bulk_subscriptions(bulk_subscription_list, user = nil, reason = nil, comment = nil, requested_date = nil, call_completion = false, options = {})

          params = {}
          params[:callCompletion] = call_completion
          params[:requestedDate] = requested_date unless requested_date.nil?

          post KILLBILL_API_BULK_ENTITLEMENT_PREFIX,
               bulk_subscription_list.to_json,
               params,
               {
                   :user => user,
                   :reason => reason,
                   :comment => comment,
               }.merge(options)
        end


      end
    end
  end
end


