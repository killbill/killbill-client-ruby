module KillBillClient
  module Model
    class Catalog < CatalogAttributesSimple

      has_many :products, KillBillClient::Model::Product

      KILLBILL_API_CATALOG_PREFIX = "#{KILLBILL_API_PREFIX}/catalog"

      class << self
        def simple_catalog(options = {})
          get "#{KILLBILL_API_CATALOG_PREFIX}/simpleCatalog",
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
      end
    end
  end
end
