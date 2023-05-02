# frozen_string_literal: true

module EE
  module Ci
    module JobTokenScope
      module RemoveProjectService
        extend ::Gitlab::Utils::Override

        override :execute
        def execute(target_project, direction)
          super.tap do |response|
            audit(project, target_project, current_user) if direction == :inbound && response.success?
          end
        end

        private

        def audit(scope, target, author)
          audit_message =
            "Project #{target.full_path} was removed from inbound list of allowed projects for #{scope.full_path}"
          event_name = 'secure_ci_job_token_project_removed'

          audit_context = {
            name: event_name,
            author: author,
            scope: scope,
            target: target,
            message: audit_message
          }

          ::Gitlab::Audit::Auditor.audit(audit_context)
        end
      end
    end
  end
end
