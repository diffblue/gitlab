# frozen_string_literal: true

module EE
  module Preloaders
    module SingleHierarchyProjectGroupPlansPreloader
      def execute
        return unless ::Gitlab::CurrentSettings.should_check_namespace_plan?
        return unless project = projects.take

        plans = project.namespace.root_ancestor.plans

        preload_plans(plans)
      end

      def preload_plans(plans)
        return unless plans.any?

        projects.each do |project|
          project.namespace.memoized_plans = plans
        end
      end
    end
  end
end
