# frozen_string_literal: true

module Ci
  module Minutes
    class UpdateBuildMinutesService < BaseService
      # Calculates consumption and updates the project and namespace statistics(legacy)
      # or ProjectMonthlyUsage and NamespaceMonthlyUsage(not legacy) based on the passed build.
      def execute(build)
        if Feature.enabled?(:ci_always_track_shared_runners_usage, build.project, default_enabled: :yaml)
          return unless build.complete?
          return unless build.duration&.positive?
          return unless build.shared_runner_build?

          ci_minutes_consumed = ::Gitlab::Ci::Minutes::BuildConsumption.new(build, build.duration).amount

          update_usage(build, ci_minutes_consumed)
        else
          legacy_update_minutes(build)
        end
      end

      private

      def legacy_update_minutes(build)
        return unless build.cost_factor_enabled?
        return unless build.complete?
        return unless build.duration&.positive?

        consumption = ::Gitlab::Ci::Minutes::BuildConsumption.new(build, build.duration).amount

        return unless consumption > 0

        ::Ci::Minutes::UpdateProjectAndNamespaceUsageWorker.perform_async(consumption, project.id, namespace.id, build.id)
      end

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
