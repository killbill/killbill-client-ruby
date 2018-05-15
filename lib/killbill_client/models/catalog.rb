module KillBillClient
  module Model
    class Catalog < CatalogAttributes

      has_many :products, KillBillClient::Model::Product

      KILLBILL_API_CATALOG_PREFIX = "#{KILLBILL_API_PREFIX}/catalog"

      class << self
        def simple_catalog(options = {})
          get "#{KILLBILL_API_CATALOG_PREFIX}",
              {},
              options
        end

        def available_addons(base_product_name, options = {})
          get "#{KILLBILL_API_CATALOG_PREFIX}/availableAddons",
              {
                  :baseProductName => base_product_name
              },
              options,
              PlanDetail
        end

        def available_base_plans(options = {})
          get "#{KILLBILL_API_CATALOG_PREFIX}/availableBasePlans",
              {},
              options,
              PlanDetail
        end

        def get_tenant_catalog_versions(options = {})

          require_multi_tenant_options!(options, "Retrieving catalog versions is only supported in multi-tenant mode")

          get "#{KILLBILL_API_CATALOG_PREFIX}/versions",
              {},
              options
        end

        def get_tenant_catalog_xml(requested_date = nil, options = {})

          require_multi_tenant_options!(options, "Retrieving a catalog is only supported in multi-tenant mode")

          params = {}
          params[:requestedDate] = requested_date if requested_date

          get "#{KILLBILL_API_CATALOG_PREFIX}/xml",
              params,
              {
                  :head => {'Accept' => "text/xml"},
                  :content_type => "text/xml",

          }.merge(options)

        end

        def get_tenant_catalog_json(requested_date = nil, options = {})

          require_multi_tenant_options!(options, "Retrieving a catalog is only supported in multi-tenant mode")

          params = {}
          params[:requestedDate] = requested_date if requested_date

          get KILLBILL_API_CATALOG_PREFIX,
              params,
              {
                  :head => {'Accept' => "application/json"},
                  :content_type => "application/json",

              }.merge(options)

        end

        def upload_tenant_catalog(catalog_xml, user = nil, reason = nil, comment = nil, options = {})

          require_multi_tenant_options!(options, "Uploading a catalog is only supported in multi-tenant mode")

          post "#{KILLBILL_API_CATALOG_PREFIX}/xml",
               catalog_xml,
               {
               },
               {
                   :head => {'Accept' => 'application/json'},
                   :content_type => 'text/xml',
                   :user => user,
                   :reason => reason,
                   :comment => comment,
               }.merge(options)
          get_tenant_catalog_json(nil, options)
        end


        def add_tenant_catalog_simple_plan(simple_plan, user = nil, reason = nil, comment = nil, options = {})

          require_multi_tenant_options!(options, "Uploading a catalog is only supported in multi-tenant mode")

          post "#{KILLBILL_API_CATALOG_PREFIX}/simplePlan",
               simple_plan.to_json,
               {
               },
               {
                   :user => user,
                   :reason => reason,
                   :comment => comment,
               }.merge(options)
        end

        def delete_catalog(user = nil, reason = nil, comment = nil, options = {})

          delete "#{KILLBILL_API_CATALOG_PREFIX}",
                 {},
                 {},
                 {
                     :user => user,
                     :reason => reason,
                     :comment => comment,
                 }.merge(options)
        end
      end
    end
  end
end
