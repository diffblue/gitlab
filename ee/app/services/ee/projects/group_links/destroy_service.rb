# frozen_string_literal: true

module EE
  module Projects
    module GroupLinks
      module DestroyService
        extend ::Gitlab::Utils::Override

        override :execute
        def execute(group_link)
          super.tap do |link|
            if link && !link&.persisted?
              log_audit_event(link)
              project_stream_audit_event(link)
            end
          end
        end

        private

        def log_audit_event(group_link)
          ::AuditEventService.new(
            current_user,
            group_link.group,
            action: :destroy
          ).for_project_group_link(group_link).security_event
        end

        def project_stream_audit_event(group_link)
          return unless current_user

          audit_context = {
            name: 'project_group_link_destroy',
            stream_only: true,
            author: current_user,
            scope: project,
            target: group_link.group,
            message: "Removed project group link"
          }

          ::Gitlab::Audit::Auditor.audit(audit_context)
        end
      end
    end
  end
end
