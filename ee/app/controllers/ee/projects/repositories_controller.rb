# frozen_string_literal: true

module EE
  module Projects
    module RepositoriesController
      extend ActiveSupport::Concern

      prepended do
        before_action :log_audit_event, only: [:archive]
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
    end
  end
end
