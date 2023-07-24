# frozen_string_literal: true

module Namespaces
  module Storage
    module CostFactor
      extend self

      FULL_COST = 1.0

      def cost_factor_for(project)
        if project.forked? && (project.root_ancestor.paid? || !project.private?)
          forks_cost_factor(project.root_ancestor)
        else
          FULL_COST
        end
      end

      def inverted_cost_factor_for_forks(root_namespace)
        FULL_COST - forks_cost_factor(root_namespace)
      end

      private

      def forks_cost_factor(root_namespace)
        if ::Gitlab::CurrentSettings.should_check_namespace_plan? &&
            ::Feature.enabled?(:namespace_storage_forks_cost_factor, root_namespace)
          ::Gitlab::CurrentSettings.namespace_storage_forks_cost_factor
        else
          FULL_COST
        end
      end
    end
  end
end
