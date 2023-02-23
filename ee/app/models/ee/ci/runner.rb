# frozen_string_literal: true

module EE
  module Ci
    module Runner
      extend ActiveSupport::Concern

      prepended do
        has_one :cost_settings, class_name: 'Ci::Minutes::CostSetting', foreign_key: :runner_id, inverse_of: :runner

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
