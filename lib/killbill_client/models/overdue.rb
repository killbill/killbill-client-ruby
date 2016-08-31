module KillBillClient
  module Model
    class Overdue < OverdueAttributes

      has_many :overdue_states, KillBillClient::Model::OverdueStateConfig

      KILLBILL_API_OVERDUE_PREFIX = "#{KILLBILL_API_PREFIX}/overdue"

      class << self

        def get_tenant_overdue_config(format, options = {})

          require_multi_tenant_options!(options, "Retrieving an overdue config is only supported in multi-tenant mode")

          get KILLBILL_API_OVERDUE_PREFIX,
              {},
              {
                  :head => {'Accept' => "application/#{format}"},
                  :content_type => "application/#{format}",
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
          get_tenant_overdue_config('xml', options)
        end
      end
    end
  end
end

