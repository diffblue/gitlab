# frozen_string_literal: true

module Ci
  module Minutes
    # Track usage of Shared Runners minutes at root namespace level.
    # This class ensures that we keep 1 record per namespace per month.
    class NamespaceMonthlyUsage < ApplicationRecord
      self.table_name = "ci_namespace_monthly_usages"

      belongs_to :namespace

      scope :current_month, -> { where(date: beginning_of_month) }
      scope :for_namespace, -> (namespace) { where(namespace: namespace) }

      def self.beginning_of_month(time = Time.current)
        time.utc.beginning_of_month
      end

      # We should pretty much always use this method to access data for the current month
      # since this will lazily create an entry if it doesn't exist.
      # For example, on the 1st of each month, when we update the usage for a namespace,
      # we will automatically generate new records and reset usage for the current month.
      #
      # Here we will also do any recalculation of additional minutes based on the
      # previous month usage.
      def self.find_or_create_current(namespace_id:)
        current_month.safe_find_or_create_by(namespace_id: namespace_id)
      end

      def self.increase_usage(usage, amount)
        return unless amount > 0

        # The use of `update_counters` ensures we do a SQL update rather than
        # incrementing the counter for the object in memory and then save it.
        # This is better for concurrent updates.
        update_counters(usage, amount_used: amount)
      end
    end
  end
end
