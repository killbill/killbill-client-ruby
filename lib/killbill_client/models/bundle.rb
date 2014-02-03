module KillBillClient
  module Model
    class Bundle < BundleAttributes

      KILLBILL_API_BUNDLES_PREFIX = "#{KILLBILL_API_PREFIX}/bundles"

      has_many :subscriptions, KillBillClient::Model::Subscription
      has_many :audit_logs, KillBillClient::Model::AuditLog

      class << self
        def find_in_batches(offset = 0, limit = 100, options = {})
          get "#{KILLBILL_API_BUNDLES_PREFIX}/#{Resource::KILLBILL_API_PAGINATION_PREFIX}",
              {
                  :offset => offset,
                  :limit => limit
              },
              options
        end

        def find_in_batches_by_search_key(search_key, offset = 0, limit = 100, options = {})
          get "#{KILLBILL_API_BUNDLES_PREFIX}/search/#{search_key}",
              {
                  :offset => offset,
                  :limit => limit
              },
              options
        end

        def find_by_id(bundle_id, options = {})
          get "#{KILLBILL_API_BUNDLES_PREFIX}/#{bundle_id}",
              {},
              options
        end

        # Return the active one
        def find_by_external_key(external_key, options = {})
          get "#{KILLBILL_API_BUNDLES_PREFIX}?externalKey=#{external_key}",
              {},
              options
        end

        # Return active and inactive ones
        def find_all_by_account_id_and_external_key(account_id, external_key, options = {})
          get "#{Account::KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/bundles?externalKey=#{external_key}",
              {},
              options
        end

      end


      # Transfer the bundle to the new account. the new account_id should be set in this object
      def transfer(bundle_id, requested_date = nil, billing_policy = nil, user = nil, reason = nil, comment = nil, options = {})

        params = {}
        params[:requestedDate] = requested_date unless requested_date.nil?
        params[:billingPolicy] = billing_policy unless billing_policy.nil?
        result = self.class.put "#{KILLBILL_API_BUNDLES_PREFIX}/#{bundle_id}",
                                to_json,
                                params,
                                {
                                    :user => user,
                                    :reason => reason,
                                    :comment => comment,
                                }.merge(options)

        result.refresh(options)
      end


      # Pause the bundle (and all its subscription)
      def pause(requested_date = nil, user = nil, reason = nil, comment = nil, options = {})

        params = {}
        params[:requestedDate] = requested_date unless requested_date.nil?
        self.class.put "#{KILLBILL_API_BUNDLES_PREFIX}/#{@bundle_id}/pause",
                                {},
                                params,
                                {
                                    :user => user,
                                    :reason => reason,
                                    :comment => comment,
                                }.merge(options)
      end


      # Resume the bundle (and all its subscription)
      def resume(requested_date = nil, user = nil, reason = nil, comment = nil, options = {})

        params = {}
        params[:requestedDate] = requested_date unless requested_date.nil?
        self.class.put "#{KILLBILL_API_BUNDLES_PREFIX}/#{@bundle_id}/resume",
                                {},
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
