module KillBillClient
  module Model
    class Tenant < TenantAttributes
      KILLBILL_API_TENANTS_PREFIX = "#{KILLBILL_API_PREFIX}/tenants"

      class << self
        def find_by_id(tenant_id, options = {})
          get "#{KILLBILL_API_TENANTS_PREFIX}/#{tenant_id}",
              {},
              options
        end

        def find_by_api_key(api_key, options = {})
          get "#{KILLBILL_API_TENANTS_PREFIX}/?apiKey=#{api_key}",
              {},
              options
        end
      end

      def create(user = nil, reason = nil, comment = nil, options = {})
        created_tenant = self.class.post KILLBILL_API_TENANTS_PREFIX,
                                         to_json,
                                         {},
                                         {
                                             :user => user,
                                             :reason => reason,
                                             :comment => comment,
                                         }.merge(options)
        #
        # Specify api_key and api_secret before making the call to retrieve the tenant object
        # otherwise that would fail with a 401
        #
        options[:api_key] = @api_key
        options[:api_secret] = @api_secret
        created_tenant.refresh(options)
      end
    end
  end
end
