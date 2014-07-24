module KillBillClient
  module Model
    module TagHelper

      AUTO_PAY_OFF_ID            = '00000000-0000-0000-0000-000000000001'
      AUTO_INVOICING_ID          = '00000000-0000-0000-0000-000000000002'
      OVERDUE_ENFORCEMENT_OFF_ID = '00000000-0000-0000-0000-000000000003'
      WRITTEN_OFF_ID             = '00000000-0000-0000-0000-000000000004'
      MANUAL_PAY_ID              = '00000000-0000-0000-0000-000000000005'
      TEST_ID                    = '00000000-0000-0000-0000-000000000006'

      def add_tag(tag_name, user = nil, reason = nil, comment = nil, options = {})
        tag_definition = TagDefinition.find_by_name(tag_name, 'NONE', options)
        if tag_definition.nil?
          tag_definition             = TagDefinition.new
          tag_definition.name        = tag_name
          tag_definition.description = 'TagDefinition automatically created by the Kill Bill Ruby client library'
          tag_definition             = TagDefinition.create(user, options)
        end

        add_tag_from_definition_id(tag_definition.id, user, reason, comment, options)
      end

      def remove_tag(tag_name, user = nil, reason = nil, comment = nil, options = {})
        tag_definition = TagDefinition.find_by_name(tag_name, 'NONE', options)
        return nil if tag_definition.nil?

        remove_tag_from_definition_id(tag_definition.id, user, reason, comment, options)
      end

      def set_tags(tag_definition_ids, user = nil, reason = nil, comment = nil, options = {})
        current_tag_definition_ids = tags(false, 'NONE', options).map { |tag| tag.tag_definition_id }

        # Find tags to remove
        tags_to_remove             = Set.new
        current_tag_definition_ids.each do |current_tag_definition_id|
          tags_to_remove << current_tag_definition_id unless tag_definition_ids.include?(current_tag_definition_id)
        end

        # Find tags to add
        tags_to_add = Set.new
        tag_definition_ids.each do |new_tag_definition_id|
          tags_to_add << new_tag_definition_id unless current_tag_definition_ids.include?(new_tag_definition_id)
        end

        remove_tags_from_definition_ids(tags_to_remove.to_a, user, reason, comment, options) unless tags_to_remove.empty?
        add_tags_from_definition_ids(tags_to_add.to_a, user, reason, comment, options) unless tags_to_add.empty?
      end

      def add_tag_from_definition_id(tag_definition_id, user = nil, reason = nil, comment = nil, options = {})
        add_tags_from_definition_ids([tag_definition_id], user, reason, comment, options)
      end

      def remove_tag_from_definition_id(tag_definition_id, user = nil, reason = nil, comment = nil, options = {})
        remove_tags_from_definition_ids([tag_definition_id], user, reason, comment, options)
      end

      def control_tag_off?(control_tag_definition_id, options)
        res = tags('NONE', options)
        !((res || []).select do |t|
          t.tag_definition_id == control_tag_definition_id
        end.first.nil?)
      end

      module ClassMethods
        def has_tags(url_prefix, id_alias)
          define_method('tags') do |included_deleted = false, audit = 'NONE', options = {}|
            self.class.get "#{url_prefix}/#{send(id_alias)}/tags",
                           {
                               :includedDeleted => included_deleted,
                               :audit           => audit
                           },
                           options,
                           Tag
          end

          define_method('add_tags_from_definition_ids') do |tag_definition_ids, user = nil, reason = nil, comment = nil, options = {}|
            created_tag = self.class.post "#{url_prefix}/#{send(id_alias)}/tags",
                                          {},
                                          {
                                              :tagList => tag_definition_ids.join(',')
                                          },
                                          {
                                              :user    => user,
                                              :reason  => reason,
                                              :comment => comment,
                                          }.merge(options),
                                          Tag
            created_tag.refresh(options)
          end

          define_method('remove_tags_from_definition_ids') do |tag_definition_ids, user = nil, reason = nil, comment = nil, options = {}|
            self.class.delete "#{url_prefix}/#{send(id_alias)}/tags",
                              {},
                              {
                                  :tagList => tag_definition_ids.join(',')
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
