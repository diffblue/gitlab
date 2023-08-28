# frozen_string_literal: true

module Namespaces
  module Storage
    module CostFactor
      extend self

      FULL_COST = 1.0

      def cost_factor_for(project)
        if project.forked? && (project.root_ancestor.paid? || !project.private?)
          forks_cost_factor
        else
          FULL_COST
        end
      end

      def inverted_cost_factor_for_forks
        FULL_COST - forks_cost_factor
      end

      private

      def forks_cost_factor
        if ::Gitlab::CurrentSettings.should_check_namespace_plan?
          ::Gitlab::CurrentSettings.namespace_storage_forks_cost_factor
        else
          FULL_COST
        end
      end
    end
  end
end
