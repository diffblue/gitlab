# frozen_string_literal: true

module EE
  module Projects
    module RepositoriesController
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override

      prepended do
        before_action :log_audit_event, only: [:archive]
        before_action :check_projects_download_throttling!, only: [:archive]
      end

      private

      def log_audit_event
        project = repository.project
        audit_context = {
          name: 'repository_download_operation',
          author: current_user || ::Gitlab::Audit::UnauthenticatedAuthor.new,
          scope: project,
          target: project,
          message: 'Repository Download Started',
          ip_address: request.remote_ip
        }

        ::Gitlab::Audit::Auditor.audit(audit_context)
      end

      def check_projects_download_throttling!
        result = ::Users::Abuse::ProjectsDownloadBanCheckService.execute(current_user, project)
        error_message = _('You are not allowed to download code from this project.')
        render(plain: error_message, status: :forbidden) if result.error?
      end
    end
  end
end
