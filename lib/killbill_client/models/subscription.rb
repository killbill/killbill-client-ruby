module KillBillClient
  module Model
    class Subscription < SubscriptionAttributes

      include KillBillClient::Model::CustomFieldHelper

      KILLBILL_API_ENTITLEMENT_PREFIX = "#{KILLBILL_API_PREFIX}/subscriptions"

      has_many :events, KillBillClient::Model::EventSubscription
      has_many :price_overrides, KillBillClient::Model::PhasePriceOverrideAttributes

      has_custom_fields KILLBILL_API_ENTITLEMENT_PREFIX, :subscription_id

      class << self
        def find_by_id(subscription_id, options = {})
          get "#{KILLBILL_API_ENTITLEMENT_PREFIX}/#{subscription_id}",
              {},
              options
        end
      end
      #
      # Create a new entitlement
      #
      #
      #
      def create(user = nil, reason = nil, comment = nil, requested_date = nil, call_completion = false, options = {})

        params                  = {}
        params[:callCompletion] = call_completion
        params[:entitlementDate]  = requested_date unless requested_date.nil?
        params[:billingDate]  = requested_date unless requested_date.nil?


        created_entitlement = self.class.post KILLBILL_API_ENTITLEMENT_PREFIX,
                                              to_json,
                                              params,
                                              {
                                                  :user    => user,
                                                  :reason  => reason,
                                                  :comment => comment,
                                              }.merge(options)
        created_entitlement.refresh(options)
      end

      #
      # Change the plan of the existing Entitlement
      #
      # @input : the hash with the new product info { product_name, billing_period, price_list}
      # @requested_date : the date when that change should occur
      # @billing_policy : the override for the billing policy {END_OF_TERM, IMMEDIATE}
      # @ call_completion : whether the call should wait for invoice/payment to be completed before calls return
      #
      def change_plan(input, user = nil, reason = nil, comment = nil,
                      requested_date = nil, billing_policy = nil, call_completion = false, options = {})

        params                  = {}
        params[:callCompletion] = call_completion
        params[:requestedDate]  = requested_date unless requested_date.nil?
        params[:billingPolicy]  = billing_policy unless billing_policy.nil?

        # Make sure account_id is set
        input[:accountId] = @account_id
        input[:productCategory] = @product_category

        return self.class.put "#{KILLBILL_API_ENTITLEMENT_PREFIX}/#{@subscription_id}",
                              input.to_json,
                              params,
                              {
                                  :user    => user,
                                  :reason  => reason,
                                  :comment => comment,
                              }.merge(options)
      end

      #
      # Cancel the entitlement at the requested date
      #
      # @requested_date : the date when that change should occur
      # @billing_policy : the override for the billing policy {END_OF_TERM, IMMEDIATE}
      #
      def cancel(user = nil, reason = nil, comment = nil, requested_date = nil, entitlementPolicy = nil, billing_policy = nil, use_requested_date_for_billing = nil, options = {})
        params                              = {}
        params[:requestedDate]              = requested_date unless requested_date.nil?
        params[:billingPolicy]              = billing_policy unless billing_policy.nil?
        params[:entitlementPolicy]          = entitlementPolicy unless entitlementPolicy.nil?
        params[:useRequestedDateForBilling] = use_requested_date_for_billing unless use_requested_date_for_billing.nil?

        self.class.delete "#{KILLBILL_API_ENTITLEMENT_PREFIX}/#{subscription_id}",
                          {},
                          params,
                          {
                              :user    => user,
                              :reason  => reason,
                              :comment => comment,
                          }.merge(options)
      end

      #
      # Uncancel a future cancelled entitlement
      #
      def uncancel(user = nil, reason = nil, comment = nil, options = {})
        params = {}
        self.class.put "#{KILLBILL_API_ENTITLEMENT_PREFIX}/#{subscription_id}/uncancel",
                       nil,
                       params,
                       {
                           :user    => user,
                           :reason  => reason,
                           :comment => comment,
                       }.merge(options)
      end

      #
      # Update Subscription BCD
      #
      def update_bcd(user = nil, reason = nil, comment = nil, effective_from_date = nil, force_past_effective_date = nil, options = {})

        params                  = {}
        params[:effectiveFromDate] = effective_from_date unless effective_from_date.nil?
        params[:forceNewBcdWithPastEffectiveDate] = force_past_effective_date unless force_past_effective_date.nil?

        return self.class.put "#{KILLBILL_API_ENTITLEMENT_PREFIX}/#{subscription_id}/bcd",
                              self.to_json,
                              params,
                              {
                                  :user    => user,
                                  :reason  => reason,
                                  :comment => comment,
                              }.merge(options)
      end


    end
  end
end
