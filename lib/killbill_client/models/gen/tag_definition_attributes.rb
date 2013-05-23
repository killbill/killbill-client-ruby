module KillBillClient
  module Model
    class TagDefinitionAttributes < Resource
      attribute :id
      attribute :is_control_tag
      attribute :name
      attribute :description
      attribute :applicable_object_types
    end
  end
end
