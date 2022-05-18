# frozen_string_literal: true

module Ci
  module Minutes
    # Track usage of Shared Runners minutes at root project level.
    # This class ensures that we keep 1 record per project per month.
    class ProjectMonthlyUsage < Ci::ApplicationRecord
      include Ci::NamespacedModelName

      belongs_to :project

      scope :current_month, -> { where(date: beginning_of_month) }

      scope :for_namespace_monthly_usage, -> (namespace_monthly_usage) do
        if Feature.enabled?(:ci_show_all_projects_with_usage_sorted_descending, namespace_monthly_usage.namespace)
          all_namespace_ids = namespace_monthly_usage.namespace.self_and_descendant_ids.ids
          where(
            date: namespace_monthly_usage.date,
            project: Ci::ProjectMirror.by_namespace_id(all_namespace_ids).select(:project_id)
          ).where('amount_used > 0 OR shared_runners_duration > 0').order(amount_used: :desc)
        else
          where(
            date: namespace_monthly_usage.date,
            project: Ci::ProjectMirror.by_namespace_id(namespace_monthly_usage.namespace_id).select(:project_id)
          )
        end
      end

      def self.beginning_of_month(time = Time.current)
        time.utc.beginning_of_month
      end

      # We should pretty much always use this method to access data for the current month
      # since this will lazily create an entry if it doesn't exist.
      # For example, on the 1st of each month, when we update the usage for a project,
      # we will automatically generate new records and reset usage for the current month.
      def self.find_or_create_current(project_id:)
        current_month.safe_find_or_create_by(project_id: project_id)
      end

      def increase_usage(increments)
        increment_params = increments.select { |_attribute, value| value > 0 }
        return if increment_params.empty?

        # The use of `update_counters` ensures we do a SQL update rather than
        # incrementing the counter for the object in memory and then save it.
        # This is better for concurrent updates.
        self.class.update_counters(self, increment_params)
      end
    end
  end
end
