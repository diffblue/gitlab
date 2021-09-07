# frozen_string_literal: true

module EE
  module Ci
    module BuildFinishedWorker
      def process_build(build)
        # Always run `super` first since it contains sync operations.
        # Failing to run sync operations would cause the worker to retry
        # and enqueueing duplicate jobs.
        super

        if requirements_available?(build) && !test_report_already_generated?(build)
          RequirementsManagement::ProcessRequirementsReportsWorker.perform_async(build.id)
        end

        if ::Gitlab.com? && build.has_security_reports?
          ::Security::TrackSecureScansWorker.perform_async(build.id)
        end
      end

      private

      def test_report_already_generated?(build)
        RequirementsManagement::TestReport.for_user_build(build.user_id, build.id).exists?
      end

      def requirements_available?(build)
        build.project.feature_available?(:requirements, build.user) &&
          !build.project.requirements.empty? &&
          Ability.allowed?(build.user, :create_requirement_test_report, build.project)
      end
    end
  end
end
