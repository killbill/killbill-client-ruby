module KillBillClient
  module Model
    class Tag < TagAttributes

      KILLBILL_API_TAGS_PREFIX = "#{KILLBILL_API_PREFIX}/tags"

      has_many :audit_logs, KillBillClient::Model::AuditLog

      class << self
        def find_in_batches(offset = 0, limit = 100, options = {})
          get "#{KILLBILL_API_TAGS_PREFIX}/#{Resource::KILLBILL_API_PAGINATION_PREFIX}",
              {
                  :offset => offset,
                  :limit  => limit
              },
              options
        end

        def find_in_batches_by_search_key(search_key, offset = 0, limit = 100, options = {})
          get "#{KILLBILL_API_TAGS_PREFIX}/search/#{search_key}",
              {
                  :offset => offset,
                  :limit  => limit
              },
              options
        end
      end

      def <=>(tag)
        tag_definition_name.downcase <=> tag.tag_definition_name.downcase
      end
    end
  end
end
