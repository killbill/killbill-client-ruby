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

        def upload_tenant_overdue_config_xml(overdue_config_xml, user = nil, reason = nil, comment = nil, options = {})
          upload_tenant_overdue_config('xml', overdue_config_xml, user, reason, comment, options)
        end


        def upload_tenant_overdue_config(format, body, user = nil, reason = nil, comment = nil, options = {})

          require_multi_tenant_options!(options, "Uploading an overdue config is only supported in multi-tenant mode")

          post KILLBILL_API_OVERDUE_PREFIX,
               body,
               {
               },
               {
                   :head => {'Accept' => "application/#{format}"},
                   :content_type => "application/#{format}",
                   :user => user,
                   :reason => reason,
                   :comment => comment,
               }.merge(options)
          get_tenant_overdue_config(format, options)
        end

      end

      def upload_tenant_overdue_config_json(user = nil, reason = nil, comment = nil, options = {})
        self.class.upload_tenant_overdue_config('json', to_json, user, reason, comment, options)
      end
    end
  end
end

