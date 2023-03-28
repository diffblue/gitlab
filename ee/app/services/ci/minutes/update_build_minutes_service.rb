# frozen_string_literal: true

module Ci
  module Minutes
    class UpdateBuildMinutesService < BaseService
      # Calculates consumption and updates the project and namespace statistics(legacy)
      # or ProjectMonthlyUsage and NamespaceMonthlyUsage(not legacy) based on the passed build.
      def execute(build)
        return unless build.complete?
        return unless build.duration&.positive?
        return unless build.shared_runner_build?

        ci_minutes_consumed =
          ::Gitlab::Ci::Minutes::Consumption
            .new(pipeline: build.pipeline, runner_matcher: build.runner.runner_matcher, duration: build.duration)
            .amount

        update_usage(build, ci_minutes_consumed)
      end

      private

      def update_usage(build, ci_minutes_consumed)
        ::Ci::Minutes::UpdateProjectAndNamespaceUsageWorker
          .perform_async(ci_minutes_consumed, project.id, namespace.id, build.id, { duration: build.duration })
      end

      def namespace
        project.shared_runners_limit_namespace
      end
    end
  end
end
