module KillBillClient
  module Model
    class Admin < AdminPaymentAttributes

      KILLBILL_API_ADMIN_PREFIX = "#{KILLBILL_API_PREFIX}/admin"
      KILLBILL_API_QUEUES_PREFIX = "#{KILLBILL_API_ADMIN_PREFIX}/queues"

      KILLBILL_API_CLOCK_PREFIX = "#{KILLBILL_API_PREFIX}/test/clock"

      class << self
        def get_queues_entries(account_id, options = {})
          get KILLBILL_API_QUEUES_PREFIX,
                    {
                        :accountId => account_id,
                        :withHistory => options[:withHistory],
                        :minDate => options[:minDate],
                        :maxDate => options[:maxDate]
                    },
                    {
                        :accept => 'application/octet-stream'
                    }.merge(options)
        end

        def fix_transaction_state(payment_id, transaction_id, transaction_status, user = nil, reason = nil, comment = nil, options = {})
          put "#{KILLBILL_API_ADMIN_PREFIX}/payments/#{payment_id}/transactions/#{transaction_id}",
              {:transactionStatus => transaction_status}.to_json,
              {},
              {
                  :user => user,
                  :reason => reason,
                  :comment => comment,
              }.merge(options)
        end

        def trigger_invoice_generation_for_parked_accounts(offset = 0, limit = 100, user =nil, options = {})
          post "#{KILLBILL_API_ADMIN_PREFIX}/invoices",
               {},
               {
                   :offset => offset,
                   :limit => limit
               },
               {
                   :user => user
               }.merge(options)
        end

        def put_in_rotation(options = {})
          put "#{KILLBILL_API_ADMIN_PREFIX}/healthcheck",
               {},
               {},
               {}.merge(options)
        end

        def put_out_of_rotation(options = {})
          delete "#{KILLBILL_API_ADMIN_PREFIX}/healthcheck",
              {},
              {},
              {}.merge(options)
        end

        def invalidates_cache(cache_name = nil, options = {})
          delete "#{KILLBILL_API_ADMIN_PREFIX}/cache",
                 {},
                 {
                     :cacheName => cache_name
                 },
                 {}.merge(options)
        end

        def invalidates_cache_by_account(account_id = nil, options = {})
          delete "#{KILLBILL_API_ADMIN_PREFIX}/cache/accounts/#{account_id}",
                 {},
                 {},
                 {}.merge(options)
        end

        def invalidates_cache_by_tenant(options = {})
          delete "#{KILLBILL_API_ADMIN_PREFIX}/cache/tenants",
                 {},
                 {},
                 {}.merge(options)
        end

        def get_clock(time_zone, options)
          params = {}
          params[:timeZone] = time_zone unless time_zone.nil?

          res = get KILLBILL_API_CLOCK_PREFIX,
                    params,
                    options
          JSON.parse res.body
        end

        def set_clock(requested_date, time_zone, options)
          params = {}
          params[:requestedDate] = requested_date unless requested_date.nil?
          params[:timeZone] = time_zone unless time_zone.nil?

          # The default 5s is not always enough
          params[:timeoutSec] ||= 10

          res = post KILLBILL_API_CLOCK_PREFIX,
                     {},
                     params,
                     {}.merge(options)
          JSON.parse res.body
        end

        def increment_kb_clock(days, weeks, months, years, time_zone, options)
          params = {}
          params[:days] = days unless days.nil?
          params[:weeks] = weeks unless weeks.nil?
          params[:months] = months unless months.nil?
          params[:years] = years unless years.nil?
          params[:timeZone] = time_zone unless time_zone.nil?

          # The default 5s is not always enough
          params[:timeoutSec] ||= 10

          res = put KILLBILL_API_CLOCK_PREFIX,
                    {},
                    params,
                    {}.merge(options)

          JSON.parse res.body
        end

      end
    end
  end
end
