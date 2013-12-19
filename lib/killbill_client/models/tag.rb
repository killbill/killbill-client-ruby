module KillBillClient
  module Model
    class Tag < TagAttributes

      has_many :audit_logs, KillBillClient::Model::AuditLog

      class << self
        def find_all_by_account_id account_id, included_deleted = false, audit = "NONE", options = {}
          get "#{Account::KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/tags",
              {
                  :includedDeleted => included_deleted,
                  :audit => audit
              },
              options
        end
      end

    end
  end
end
