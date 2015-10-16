module KillBillClient
  module Model
    class PluginInfo < PluginInfoAttributes

      KILLBILL_API_TENANTS_PREFIX = "#{KILLBILL_API_PREFIX}/pluginsInfo"

      has_many :services, KillBillClient::Model::PluginServiceInfoAttributes

      class << self

        def plugins_info(options = {})
          get KILLBILL_API_TENANTS_PREFIX,
              {},
              options
        end

      end

    end
  end
end
