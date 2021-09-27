# frozen_string_literal: true

module Ci
  module Minutes
    class UpdateBuildMinutesService < BaseService
      # Calculates consumption and updates the project and namespace statistics(legacy)
      # or ProjectMonthlyUsage and NamespaceMonthlyUsage(not legacy) based on the passed build.
      def execute(build)
        return unless build.cost_factor_enabled?
        return unless build.complete?
        return unless build.duration&.positive?

        consumption = ::Gitlab::Ci::Minutes::BuildConsumption.new(build, build.duration).amount

        return unless consumption > 0

        update_minutes(consumption, build)
      end

      private

      def update_minutes(consumption, build)
        ::Ci::Minutes::UpdateProjectAndNamespaceUsageWorker.perform_async(consumption, project.id, namespace.id, build.id)
      end

      def namespace
        project.shared_runners_limit_namespace
      end
    end
  end
end
