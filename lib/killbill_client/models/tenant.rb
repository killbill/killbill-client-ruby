module KillBillClient
  module Model
    class Tenant < TenantAttributes
      KILLBILL_API_TENANTS_PREFIX = "#{KILLBILL_API_PREFIX}/tenants"

      has_many :audit_logs, KillBillClient::Model::AuditLog

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

        def get_tenant_plugin_config(plugin_name, options = {})
          if options[:api_key].nil? || options[:api_secret].nil?
            raise ArgumentError, "Retrieving a plugin config is only supported in multi-tenant mode"
          end

          uri =  KILLBILL_API_TENANTS_PREFIX + "/uploadPluginConfig/" + plugin_name
          get uri,
              {},
              {
              }.merge(options),
              KillBillClient::Model::TenantKeyAttributes
        end

        def upload_tenant_plugin_config(plugin_name, plugin_config, user = nil, reason = nil, comment = nil, options = {})
          if options[:api_key].nil? || options[:api_secret].nil?
            raise ArgumentError, "Uploading a plugin config is only supported in multi-tenant mode"
          end

          uri =  KILLBILL_API_TENANTS_PREFIX + "/uploadPluginConfig/" + plugin_name
          post uri,
               plugin_config,
               {
               },
               {
                   :content_type => 'text/plain',
                   :user => user,
                   :reason => reason,
                   :comment => comment,
               }.merge(options)
          get_tenant_plugin_config(plugin_name, options)
        end

        def delete_tenant_plugin_config(plugin_name, user = nil, reason = nil, comment = nil, options = {})
          if options[:api_key].nil? || options[:api_secret].nil?
            raise ArgumentError, "Uploading a plugin config is only supported in multi-tenant mode"
          end

          uri =  KILLBILL_API_TENANTS_PREFIX + "/uploadPluginConfig/" + plugin_name
          delete uri,
               {},
               {
               },
               {
                   :content_type => 'text/plain',
                   :user => user,
                   :reason => reason,
                   :comment => comment,
               }.merge(options)

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
