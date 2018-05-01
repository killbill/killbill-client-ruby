module KillBillClient
  module Model
    module AuditLogWithHistoryHelper

      module ClassMethods
        def has_audit_logs_with_history(url_prefix, id_alias)
          define_method('audit_logs_with_history') do |*args|
            account_id = args[0]
            options = args[1] || {}

            self.class.get "#{url_prefix}/#{send(id_alias)}/auditLogsWithHistory",
                           {
                               :accountId => account_id
                           },
                           options,
                           AuditLog
          end
        end
      end

      def self.included(klass)
        klass.extend ClassMethods
      end
    end
  end
end