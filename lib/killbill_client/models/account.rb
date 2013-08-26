module KillBillClient
  module Model
    class Account < AccountAttributesWithBalance
      KILLBILL_API_ACCOUNTS_PREFIX = "#{KILLBILL_API_PREFIX}/accounts"

      class << self
        def find_by_id(account_id, with_balance = false, with_balance_and_cba = false, options = {})
          get "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}",
              {
                  :accountWithBalance => with_balance,
                  :accountWithBalanceAndCBA => with_balance_and_cba
              },
              options
        end
      end

      def create(user = nil, reason = nil, comment = nil, options = {})
        created_account = self.class.post KILLBILL_API_ACCOUNTS_PREFIX,
                                          to_json,
                                          {},
                                          {
                                              :user => user,
                                              :reason => reason,
                                              :comment => comment,
                                          }.merge(options)
        created_account.refresh(options)
      end

      def payments(options = {})
        self.class.get "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/payments",
                       {},
                       options,
                       Payment
      end

      def tags(audit = 'NONE', options = {})
        self.class.get "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/tags",
                       {
                           :audit => audit
                       },
                       options,
                       Tag
      end

      def add_tag(tag_name, user = nil, reason = nil, comment = nil, options = {})
        tag_definition = TagDefinition.find_by_name(tag_name)
        if tag_definition.nil?
          tag_definition = TagDefinition.new
          tag_definition.name = tag_name
          tag_definition.description = "Tag created for account #{@account_id}"
          tag_definition = TagDefinition.create(user, options)
        end

        created_tag = self.class.post "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/tags",
                                      {},
                                      {
                                          :tagList => tag_definition.id
                                      },
                                      {
                                          :user => user,
                                          :reason => reason,
                                          :comment => comment,
                                      }.merge(options),
                                      Tag
        created_tag.refresh(options)
      end

      def remove_tag(tag_name, user = nil, reason = nil, comment = nil, options = {})
        tag_definition = TagDefinition.find_by_name(tag_name)
        return nil if tag_definition.nil?

        self.class.delete "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/tags",
                          {
                              :tagList => tag_definition.id
                          },
                          {
                              :user => user,
                              :reason => reason,
                              :comment => comment,
                          }.merge(options)
      end
    end
  end
end
