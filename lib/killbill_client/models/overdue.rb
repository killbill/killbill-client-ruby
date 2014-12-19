module KillBillClient
  module Model
    class Overdue < OverdueStateAttributes

      KILLBILL_API_OVERDUE_PREFIX = "#{KILLBILL_API_PREFIX}/overdue"

      class << self
        def get_tenant_overdue_config(options = {})
          get KILLBILL_API_OVERDUE_PREFIX,
              {},
              {
                  :head => {'Accept' => 'application/xml'},
              }.merge(options)
        end

        def upload_tenant_overdue_config(overdue_config_xml, user = nil, reason = nil, comment = nil, options = {})
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

