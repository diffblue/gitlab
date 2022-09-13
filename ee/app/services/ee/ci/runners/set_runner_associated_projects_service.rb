# frozen_string_literal: true

module EE
  module Ci
    module Runners
      module SetRunnerAssociatedProjectsService
        extend ::Gitlab::Utils::Override

        override :execute
        def execute
          super.tap do |result|
            audit_event_service(result)
          end
        end

        private

        def audit_event_service(result)
          return if result.error?

          audit_context = {
            name: 'set_runner_associated_projects',
            author: current_user,
            scope: current_user,
            target: runner,
            target_details: runner_path,
            message: 'Changed CI runner project assignments',
            additional_details: {
              action: :custom
            }
          }
          ::Gitlab::Audit::Auditor.audit(audit_context)
        end

        def runner_path
          url_helpers = ::Gitlab::Routing.url_helpers

          url_helpers.project_runner_path(runner.owner_project, runner)
        end
      end
    end
  end
end
