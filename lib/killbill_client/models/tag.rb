module KillBillClient
  module Model
    class Tag < TagAttributes

      has_many :audit_logs, KillBillClient::Model::AuditLog

      class << self
        def find_all_by_account_id account_id, audit = "NONE", options = {}
          get "#{Account::KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/tags",
              {
                  :audit => audit
              },
              options
        end
      end

    end
  end
end
