module KillBillClient
  module Model
    class Overdue < OverdueStateAttributes

      KILLBILL_API_OVERDUE_PREFIX = "#{KILLBILL_API_PREFIX}/overdue"

      class << self
        def get_tenant_overdue_config(options = {})

          require_multi_tenant_options!(options, "Retrieving an overdue config is only supported in multi-tenant mode")

          get KILLBILL_API_OVERDUE_PREFIX,
              {},
              {
                  :head => {'Accept' => 'application/xml'},
              }.merge(options)
        end

        def upload_tenant_overdue_config(overdue_config_xml, user = nil, reason = nil, comment = nil, options = {})

          require_multi_tenant_options!(options, "Uploading an overdue config is only supported in multi-tenant mode")

          post KILLBILL_API_OVERDUE_PREFIX,
               overdue_config_xml,
               {
               },
               {
                   :head => {'Accept' => 'application/xml'},
                   :content_type => 'application/xml',
                   :user => user,
                   :reason => reason,
                   :comment => comment,
               }.merge(options)
          get_tenant_overdue_config(options)
        end
      end
    end
  end
end

