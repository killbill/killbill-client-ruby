module KillBillClient
  module Model
    class RoleDefinition < RoleDefinitionAttributes

      def create(user = nil, reason = nil, comment = nil, options = {})
        created_role = self.class.post "#{Security::KILLBILL_API_SECURITY_PREFIX}/roles",
                                       to_json,
                                       {},
                                       {
                                           :user => user,
                                           :reason => reason,
                                           :comment => comment,
                                       }.merge(options)
        created_role.refresh(options)
      end
    end
  end
end
