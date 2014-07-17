module KillBillClient
  module Model
    class Account < AccountAttributes

      has_many :audit_logs, KillBillClient::Model::AuditLog

      AUTO_PAY_OFF_ID            = '00000000-0000-0000-0000-000000000001'
      AUTO_INVOICING_ID          = '00000000-0000-0000-0000-000000000002'
      OVERDUE_ENFORCEMENT_OFF_ID = '00000000-0000-0000-0000-000000000003'
      WRITTEN_OFF_ID             = '00000000-0000-0000-0000-000000000004'
      MANUAL_PAY_ID              = '00000000-0000-0000-0000-000000000005'
      TEST_ID                    = '00000000-0000-0000-0000-000000000006'

      KILLBILL_API_ACCOUNTS_PREFIX = "#{KILLBILL_API_PREFIX}/accounts"

      class << self
        def find_in_batches(offset = 0, limit = 100, with_balance = false, with_balance_and_cba = false, options = {})
          get "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{Resource::KILLBILL_API_PAGINATION_PREFIX}",
              {
                  :offset                   => offset,
                  :limit                    => limit,
                  :accountWithBalance       => with_balance,
                  :accountWithBalanceAndCBA => with_balance_and_cba
              },
              options
        end

        def find_by_id(account_id, with_balance = false, with_balance_and_cba = false, options = {})
          get "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}",
              {
                  :accountWithBalance       => with_balance,
                  :accountWithBalanceAndCBA => with_balance_and_cba
              },
              options
        end

        def find_by_external_key(external_key, with_balance = false, with_balance_and_cba = false, options = {})
          get "#{KILLBILL_API_ACCOUNTS_PREFIX}",
              {
                  :externalKey              => external_key,
                  :accountWithBalance       => with_balance,
                  :accountWithBalanceAndCBA => with_balance_and_cba
              },
              options
        end

        def find_in_batches_by_search_key(search_key, offset = 0, limit = 100, with_balance = false, with_balance_and_cba = false, options = {})
          get "#{KILLBILL_API_ACCOUNTS_PREFIX}/search/#{search_key}",
              {
                  :offset                   => offset,
                  :limit                    => limit,
                  :accountWithBalance       => with_balance,
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
                                              :user    => user,
                                              :reason  => reason,
                                              :comment => comment,
                                          }.merge(options)
        created_account.refresh(options)
      end

      def bundles(options = {})
        self.class.get "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/bundles",
                       {},
                       options,
                       Bundle
      end

      def invoices(with_items=false, options = {})
        self.class.get "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/invoices",
                       {
                           :withItems => with_items
                       },
                       options,
                       Invoice
      end

      def payments(options = {})
        self.class.get "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/payments",
                       {},
                       options,
                       Payment
      end

      def overdue(options = {})
        self.class.get "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/overdue",
                       {},
                       options,
                       OverdueStateAttributes
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
        tag_definition = TagDefinition.find_by_name(tag_name, options)
        if tag_definition.nil?
          tag_definition             = TagDefinition.new
          tag_definition.name        = tag_name
          tag_definition.description = "Tag created for account #{@account_id}"
          tag_definition             = TagDefinition.create(user, options)
        end

        add_tag_from_definition_id(tag_definition.id, user, reason, comment, options)
      end

      def remove_tag(tag_name, user = nil, reason = nil, comment = nil, options = {})
        tag_definition = TagDefinition.find_by_name(tag_name)
        return nil if tag_definition.nil?

        self.class.delete "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/tags",
                          {},
                          {
                              :tagList => tag_definition.id
                          },
                          {
                              :user    => user,
                              :reason  => reason,
                              :comment => comment,
                          }.merge(options)
      end

      def custom_fields(audit = 'NONE', options = {})
        self.class.get "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/customFields",
                       {
                           :audit => audit
                       },
                       options,
                       CustomField
      end

      def add_custom_field(custom_fields, user = nil, reason = nil, comment = nil, options = {})
        body         = custom_fields.is_a?(Enumerable) ? custom_fields : [custom_fields]
        custom_field = self.class.post "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/customFields",
                                       body.to_json,
                                       {},
                                       {
                                           :user    => user,
                                           :reason  => reason,
                                           :comment => comment,
                                       }.merge(options),
                                       CustomField
        custom_field.refresh(options)
      end

      def remove_custom_field(custom_fields, user = nil, reason = nil, comment = nil, options = {})
        custom_fields_param = custom_fields.is_a?(Enumerable) ? custom_fields.join(",") : custom_fields
        self.class.delete "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/customFields",
                          {},
                          {
                              :customFieldList => custom_fields_param
                          },
                          {
                              :user    => user,
                              :reason  => reason,
                              :comment => comment,
                          }.merge(options)
      end

      def auto_pay_off?(options = {})
        control_tag_off?(AUTO_PAY_OFF_ID, options)
      end

      def set_auto_pay_off(user = nil, reason = nil, comment = nil, options = {})
        add_tag_from_definition_id(AUTO_PAY_OFF_ID, user, reason, comment, options)
      end

      def auto_invoicing?(options = {})
        control_tag_off?(AUTO_INVOICING_ID, options)
      end

      def set_auto_invoicing(user = nil, reason = nil, comment = nil, options = {})
        add_tag_from_definition_id(AUTO_INVOICING_ID, user, reason, comment, options)
      end

      def overdue_enforcement_off?(options = {})
        control_tag_off?(OVERDUE_ENFORCEMENT_OFF_ID, options)
      end

      def set_overdue_enforcement_off(user = nil, reason = nil, comment = nil, options = {})
        add_tag_from_definition_id(OVERDUE_ENFORCEMENT_OFF_ID, user, reason, comment, options)
      end

      def written_off?(options = {})
        control_tag_off?(WRITTEN_OFF_ID, options)
      end

      def set_written_off(user = nil, reason = nil, comment = nil, options = {})
        add_tag_from_definition_id(WRITTEN_OFF_ID, user, reason, comment, options)
      end

      def manual_pay?(options = {})
        control_tag_off?(MANUAL_PAY_ID, options)
      end

      def set_manual_pay(user = nil, reason = nil, comment = nil, options = {})
        add_tag_from_definition_id(MANUAL_PAY_ID, user, reason, comment, options)
      end

      def test?(options = {})
        control_tag_off?(TEST_ID, options)
      end

      def set_test(user = nil, reason = nil, comment = nil, options = {})
        add_tag_from_definition_id(TEST_ID, user, reason, comment, options)
      end

      def add_email(email, user = nil, reason = nil, comment = nil, options = {})
        self.class.post "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/emails",
                        {
                            # TODO Required ATM
                            :accountId => account_id,
                            :email => email
                        }.to_json,
                        {},
                        {
                            :user    => user,
                            :reason  => reason,
                            :comment => comment,
                        }.merge(options)
      end

      def remove_email(email, user = nil, reason = nil, comment = nil, options = {})
        self.class.delete "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/emails/#{email}",
                          {},
                          {},
                          {
                              :user    => user,
                              :reason  => reason,
                              :comment => comment,
                          }.merge(options)
      end

      def emails(audit = 'NONE', options = {})
        self.class.get "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/emails",
                       {
                           :audit => audit
                       },
                       options,
                       AccountEmailAttributes
      end

      def update_email_notifications(user = nil, reason = nil, comment = nil, options = {})
        self.class.put "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/emailNotifications",
                       to_json,
                       {},
                       {
                           :user    => user,
                           :reason  => reason,
                           :comment => comment,
                       }.merge(options)
      end

      private

      def control_tag_off?(control_tag_definition_id, options)
        res = tags('NONE', options)
        !((res || []).select do |t|
          t.tag_definition_id == control_tag_definition_id
        end.first.nil?)
      end

      def add_tag_from_definition_id(tag_definition_id, user = nil, reason = nil, comment = nil, options = {})
        created_tag = self.class.post "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/tags",
                                      {},
                                      {
                                          :tagList => tag_definition_id
                                      },
                                      {
                                          :user    => user,
                                          :reason  => reason,
                                          :comment => comment,
                                      }.merge(options),
                                      Tag
        created_tag.refresh(options)
      end

    end
  end
end
