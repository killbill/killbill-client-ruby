module KillBillClient
  module Model
    class Invoice < InvoiceAttributes
      KILLBILL_API_INVOICES_PREFIX = "#{KILLBILL_API_PREFIX}/invoices"
      KILLBILL_API_DRY_RUN_INVOICES_PREFIX = "#{KILLBILL_API_INVOICES_PREFIX}/dryRun"

      has_many :audit_logs, KillBillClient::Model::AuditLog
      has_many :items, KillBillClient::Model::InvoiceItem
      has_many :credits, KillBillClient::Model::Credit

      create_alias :bundle_keys, :external_bundle_keys

      class << self
        def find_by_id_or_number(id_or_number, with_items = true, audit = "NONE", options = {})
          get "#{KILLBILL_API_INVOICES_PREFIX}/#{id_or_number}",
              {
                  :withItems => with_items,
                  :audit     => audit
              },
              options
        end

        def find_in_batches(offset = 0, limit = 100, options = {})
          get "#{KILLBILL_API_INVOICES_PREFIX}/#{Resource::KILLBILL_API_PAGINATION_PREFIX}",
              {
                  :offset => offset,
                  :limit  => limit
              },
              options
        end

        def find_in_batches_by_search_key(search_key, offset = 0, limit = 100, options = {})
          get "#{KILLBILL_API_INVOICES_PREFIX}/search/#{search_key}",
              {
                  :offset => offset,
                  :limit  => limit
              },
              options
        end

        def as_html(invoice_id, options = {})
          get "#{KILLBILL_API_INVOICES_PREFIX}/#{invoice_id}/html",
              {},
              {
                  :accept => 'text/html'
              }.merge(options)
        end

        def trigger_invoice(account_id, target_date, user = nil, reason = nil, comment = nil, options = {})
          query_map              = {:accountId => account_id}
          query_map[:targetDate] = target_date if !target_date.nil?

          begin
            res = post "#{KILLBILL_API_INVOICES_PREFIX}/",
                       {},
                       query_map,
                       {
                           :user    => user,
                           :reason  => reason,
                           :comment => comment,
                       }.merge(options),
                       Invoice

            res.refresh(options)

          rescue KillBillClient::API::BadRequest => e
            # No invoice to generate : TODO parse json to verify this is indeed the case
          end
        end

        def trigger_invoice_dry_run(account_id, target_date, options = {})
          query_map              = {:accountId => account_id}
          query_map[:targetDate] = target_date if !target_date.nil?

          begin
            res = post "#{KILLBILL_API_DRY_RUN_INVOICES_PREFIX}",
                       {},
                       query_map,
                       {
                           :user    => 'trigger_invoice_dry_run',
                           :reason  => '',
                           :comment => '',
                       }.merge(options),
                       Invoice

            res.refresh(options)

          rescue KillBillClient::API::NotFound => e
            nil
          end
        end


        def create_subscription_dry_run(account_id, bundle_id, target_date, product_name, product_category,
            billing_period, price_list_name,  options = {})
          query_map              = {:accountId => account_id}
          query_map[:targetDate] = target_date if !target_date.nil?

          dry_run = InvoiceDryRunAttributes.new
          dry_run.dry_run_action = 'START_BILLING'
          dry_run.product_name = product_name
          dry_run.product_category = product_category
          dry_run.billing_period = billing_period
          dry_run.price_list_name = price_list_name
          dry_run.bundle_id = bundle_id

          begin
            res = post "#{KILLBILL_API_DRY_RUN_INVOICES_PREFIX}",
                       dry_run.to_json,
                       query_map,
                       {
                           :user    => 'create_subscription_dry_run',
                           :reason  => '',
                           :comment => '',
                       }.merge(options),
                       Invoice

            res.refresh(options)
          rescue KillBillClient::API::NotFound => e
            nil
          end
        end

        def change_plan_dry_run(account_id, bundle_id, subscription_id, target_date, product_name, product_category, billing_period, price_list_name,
            effective_date, billing_policy, options = {})
          query_map              = {:accountId => account_id}
          query_map[:targetDate] = target_date if !target_date.nil?

          dry_run = InvoiceDryRunAttributes.new
          dry_run.dry_run_action = 'CHANGE'
          dry_run.product_name = product_name
          dry_run.product_category = product_category
          dry_run.billing_period = billing_period
          dry_run.price_list_name = price_list_name
          dry_run.effective_date = effective_date
          dry_run.billing_policy = billing_policy
          dry_run.bundle_id = bundle_id
          dry_run.subscription_id = subscription_id

          begin
            res = post "#{KILLBILL_API_DRY_RUN_INVOICES_PREFIX}",
                       dry_run.to_json,
                       query_map,
                       {
                           :user    => 'change_plan_dry_run',
                           :reason  => '',
                           :comment => '',
                       }.merge(options),
                       Invoice

            res.refresh(options)
          rescue KillBillClient::API::NotFound => e
            nil
          end
        end


        def cancel_subscription_dry_run(account_id, bundle_id, subscription_id, target_date,
            effective_date, billing_policy,  options = {})
          query_map              = {:accountId => account_id}
          query_map[:targetDate] = target_date if !target_date.nil?

          dry_run = InvoiceDryRunAttributes.new
          dry_run.dry_run_action = 'STOP_BILLING'
          dry_run.effective_date = effective_date
          dry_run.billing_policy = billing_policy
          dry_run.bundle_id = bundle_id
          dry_run.subscription_id = subscription_id


          begin
            res = post "#{KILLBILL_API_DRY_RUN_INVOICES_PREFIX}",
                       dry_run.to_json,
                       query_map,
                       {
                           :user    => 'cancel_subscription_dry_run',
                           :reason  => '',
                           :comment => '',
                       }.merge(options),
                       Invoice

            res.refresh(options)

          rescue KillBillClient::API::NotFound => e
            nil
          end
        end

      end

      def payments(with_plugin_info = false, audit = 'NONE', options = {})
        self.class.get "#{KILLBILL_API_INVOICES_PREFIX}/#{invoice_id}/payments",
                       {
                           :withPluginInfo => with_plugin_info,
                           :audit          => audit
                       },
                       options,
                       InvoicePayment
      end
    end
  end
end
