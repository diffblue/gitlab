# frozen_string_literal: true

module EE
  module Groups
    module GroupLinks
      module CreateService
        extend ::Gitlab::Utils::Override

        override :after_successful_save
        def after_successful_save
          super

          log_audit_event
        end

        def log_audit_event
          audit_context = {
            name: "group_share_with_group_link_created",
            author: current_user,
            scope: link.shared_group,
            target: link.shared_with_group,
            stream_only: false,
            message: "Invited #{link.shared_with_group.name} " \
                     "to the group #{link.shared_group.name}"
          }

          ::Gitlab::Audit::Auditor.audit(audit_context)
        end
      end
    end
  end
end
