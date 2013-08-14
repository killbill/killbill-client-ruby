module KillBillClient
  module Model
    class Security < Resource
      KILLBILL_API_SECURITY_PREFIX = "#{KILLBILL_API_PREFIX}/security"

      class << self
        def find_permissions(options = {})
          get "#{KILLBILL_API_SECURITY_PREFIX}/permissions",
              {},
              options
        end
      end
    end
  end
end
