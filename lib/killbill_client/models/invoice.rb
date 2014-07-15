module KillBillClient
  module Model
    class Invoice < InvoiceAttributes
      KILLBILL_API_INVOICES_PREFIX = "#{KILLBILL_API_PREFIX}/invoices"

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

        def trigger_invoice(account_id, target_date, dry_run, user = nil, reason = nil, comment = nil, options = {})
          query_map              = {:accountId => account_id}
          query_map[:targetDate] = target_date if !target_date.nil?
          query_map[:dryRun]     = dry_run if !dry_run.nil?

          begin
            res = post "#{KILLBILL_API_INVOICES_PREFIX}",
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
