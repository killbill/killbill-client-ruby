module KillBillClient
  module Model
    class TagDefinition < TagDefinitionAttributes
      KILLBILL_API_TAG_DEFINITIONS_PREFIX = "#{KILLBILL_API_PREFIX}/tagDefinitions"

      class << self
        def all(options = {})
          get KILLBILL_API_TAG_DEFINITIONS_PREFIX,
              {},
              options
        end

        def find_by_name(name, options = {})
          self.all(options).select { |tag_definition| tag_definition.name == name }.first
        end
      end

      def create(user = nil, reason = nil, comment = nil, options = {})
        created_tag_definition = self.class.post KILLBILL_API_TAG_DEFINITIONS_PREFIX,
                                                 to_json,
                                                 {},
                                                 {
                                                     :user => user,
                                                     :reason => reason,
                                                     :comment => comment,
                                                 }.merge(options)
        created_tag_definition.refresh(options)
      end
    end
  end
end
