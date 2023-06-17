# frozen_string_literal: true

module EE
  module Projects
    module ImportService
      extend ::Gitlab::Utils::Override

      override :validate_repository_size!
      def validate_repository_size!
        ::Import::ValidateRepositorySizeService.new(project).execute
      end

      override :after_execute_hook
      def after_execute_hook
        super

        log_audit_event if project.group.present?
      end

      private

      def log_audit_event
        audit_context = {
          name: 'project_imported',
          author: current_user,
          scope: project.group,
          target: project,
          message: 'Project imported',
          target_details: project.full_path
        }

        ::Gitlab::Audit::Auditor.audit(audit_context)
      end
    end
  end
end
