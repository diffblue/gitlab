# frozen_string_literal: true

module EE
  module Ci
    module Runner
      extend ActiveSupport::Concern

      prepended do
        def self.any_shared_runners_with_enabled_cost_factor?(project)
          if project.public?
            instance_type.where('public_projects_minutes_cost_factor > 0').exists?
          else
            instance_type.where('private_projects_minutes_cost_factor > 0').exists?
          end
        end
      end

      def cost_factor_for_project(project)
        cost_factor.for_project(project)
      end

      def cost_factor_enabled?(project)
        cost_factor.enabled?(project)
      end

      # TODO: remove this method when ci_queuing_use_denormalized_data_strategy
      # feature flag is removed
      def visibility_levels_without_minutes_usage
        ::Gitlab::VisibilityLevel.options.values.reject do |visibility_level|
          cost_factor.for_visibility(visibility_level) > 0
        end
      end

      def matches_build?(build)
        return false unless super(build)

        allowed_for_plans?(build)
      end

      def allowed_for_plans?(build)
        return true unless ::Feature.enabled?(:ci_runner_separation_by_plan, self, type: :ops)
        return true if allowed_plans.empty?

        plans = build.namespace&.plans || []

        common = allowed_plans & plans.map(&:name)
        common.any?
      end

      private

      def cost_factor
        strong_memoize(:cost_factor) do
          ::Gitlab::Ci::Minutes::CostFactor.new(runner_matcher)
        end
      end
    end
  end
end
