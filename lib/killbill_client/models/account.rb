module KillBillClient
  module Model
    class Account < AccountAttributesWithBalance
      KILLBILL_API_ACCOUNTS_PREFIX = "#{KILLBILL_API_PREFIX}/accounts"

      class << self
        def find_by_id(account_id, with_balance = false, with_balance_and_cba = false)
          get "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}",
              {
                  :accountWithBalance => with_balance,
                  :accountWithBalanceAndCBA => with_balance_and_cba
              }
        end
      end

      def create(user = nil, reason = nil, comment = nil)
        created_account = self.class.post KILLBILL_API_ACCOUNTS_PREFIX,
                                          to_json,
                                          {},
                                          {
                                              :user => user,
                                              :reason => reason,
                                              :comment => comment,
                                          }
        created_account.refresh
      end

      def payments
        self.class.get "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/payments",
                       {},
                       {},
                       Payment
      end

      def tags(audit = 'NONE')
        self.class.get "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/tags",
                       {
                           :audit => audit
                       },
                       {},
                       Tag
      end

      def add_tag(tag_name, user = nil, reason = nil, comment = nil)
        tag_definition = TagDefinition.find_by_name(tag_name)
        if tag_definition.nil?
          tag_definition = TagDefinition.new
          tag_definition.name = tag_name
          tag_definition.description = "Tag created for account #{@account_id}"
          tag_definition = TagDefinition.create(user)
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
                                      },
                                      Tag
        created_tag.refresh
      end

      def remove_tag(tag_name, user = nil, reason = nil, comment = nil)
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
                          }
      end
    end
  end
end
