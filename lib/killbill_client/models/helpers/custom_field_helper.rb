module KillBillClient
  module Model
    module CustomFieldHelper

      module ClassMethods
        def has_custom_fields(url_prefix, id_alias)
          define_method('custom_fields') do |audit = 'NONE', options = {}|
            self.class.get "#{url_prefix}/#{send(id_alias)}/customFields",
                           {
                               :audit => audit
                           },
                           options,
                           CustomField
          end

          define_method('add_custom_field') do |custom_fields, user = nil, reason = nil, comment = nil, options = {}|
            body         = custom_fields.is_a?(Enumerable) ? custom_fields : [custom_fields]
            custom_field = self.class.post "#{url_prefix}/#{send(id_alias)}/customFields",
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

          define_method('remove_custom_field') do |custom_fields, user = nil, reason = nil, comment = nil, options = {}|
            custom_fields_param = custom_fields.is_a?(Enumerable) ? custom_fields.join(",") : custom_fields
            self.class.delete "#{url_prefix}/#{send(id_alias)}/customFields",
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
        end
      end

      def self.included(klass)
        klass.extend ClassMethods
      end
    end
  end
end
