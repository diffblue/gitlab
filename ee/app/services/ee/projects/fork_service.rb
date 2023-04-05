# frozen_string_literal: true

module EE
  module Projects
    module ForkService
      extend ::Gitlab::Utils::Override

      # rubocop:disable Gitlab/ModuleWithInstanceVariables
      override :stream_audit_event
      def stream_audit_event(forked_project)
        audit_context = {
          name: 'project_fork_operation',
          stream_only: true,
          author: current_user,
          scope: @project,
          target: @project,
          message: "Forked project to #{forked_project.full_path}"
        }

        ::Gitlab::Audit::Auditor.audit(audit_context)
      end
      # rubocop:enable Gitlab/ModuleWithInstanceVariables

      # rubocop:disable Gitlab/ModuleWithInstanceVariables
      override :allowed_fork?
      def allowed_fork?
        result = ::Users::Abuse::ProjectsDownloadBanCheckService.execute(current_user, @project)
        return false if result.error?

        super
      end
      # rubocop:enable Gitlab/ModuleWithInstanceVariables
    end
  end
end
