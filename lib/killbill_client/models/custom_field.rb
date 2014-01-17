module KillBillClient
  module Model
    class CustomField < CustomFieldAttributes
      KILLBILL_API_CUSTOM_FIELDS_PREFIX = "#{KILLBILL_API_PREFIX}/customFields"

      has_many :audit_logs, KillBillClient::Model::AuditLog

      class << self
        def find_all_by_account_id(account_id, included_deleted = false, audit = "NONE", options = {})
          get "#{Account::KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/customFields",
              {
                  :includedDeleted => included_deleted,
                  :audit => audit
              },
              options
        end

        def find_in_batches(offset = 0, limit = 100, options = {})
          get "#{KILLBILL_API_CUSTOM_FIELDS_PREFIX}/#{Resource::KILLBILL_API_PAGINATION_PREFIX}",
              {
                  :offset => offset,
                  :limit => limit
              },
              options
        end

        def find_in_batches_by_search_key(search_key, offset = 0, limit = 100, options = {})
          get "#{KILLBILL_API_CUSTOM_FIELDS_PREFIX}/search/#{search_key}",
              {
                  :offset => offset,
                  :limit => limit
              },
              options
        end
      end
    end
  end
end
