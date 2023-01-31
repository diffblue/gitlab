# frozen_string_literal: true

module EE
  module Projects
    module GroupLinks
      module DestroyService
        extend ::Gitlab::Utils::Override

        override :execute
        def execute(group_link)
          super.tap do |link|
            send_audit_event(link) if link && !link&.persisted?
          end
        end

        private

        def send_audit_event(group_link)
          return unless current_user

          audit_context = {
            name: 'project_group_link_deleted',
            author: current_user,
            scope: group_link.group,
            target: project,
            target_details: project.full_path,
            message: 'Removed project group link',
            additional_details: {
              remove: 'project_access'
            }
          }

          ::Gitlab::Audit::Auditor.audit(audit_context)
        end
      end
    end
  end
end
