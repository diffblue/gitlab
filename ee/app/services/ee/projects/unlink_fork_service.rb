# frozen_string_literal: true

module EE
  module Projects
    module UnlinkForkService
      extend ::Gitlab::Utils::Override

      override :execute
      def execute
        super.tap do |result|
          log_audit_event if result.present?
        end
      end

      def log_audit_event
        audit_context = {
          name: 'project_fork_relationship_removed',
          author: current_user,
          scope: project,
          target: project,
          message: "Project unlinked from #{project.forked_from_project&.name}",
          created_at: DateTime.current
        }

        ::Gitlab::Audit::Auditor.audit(audit_context)
      end
    end
  end
end
