# frozen_string_literal: true

module Ci
  module Minutes
    # Track usage of Shared Runners minutes at root namespace level.
    # This class ensures that we keep 1 record per namespace per month.
    class NamespaceMonthlyUsage < Ci::ApplicationRecord
      include Ci::NamespacedModelName
      include AfterCommitQueue
      include IgnorableColumns

      belongs_to :namespace

      ignore_column :new_amount_used, remove_with: '15.7', remove_after: '2022-11-22'

      scope :current_month, -> { where(date: beginning_of_month) }
      scope :for_namespace, -> (namespace) { where(namespace: namespace) }
      scope :by_namespace_and_date, -> (namespace, date) {
        where(namespace: namespace, date: date)
      }

      def self.previous_usage(namespace)
        for_namespace(namespace).where("#{quoted_table_name}.date < :date", date: beginning_of_month).order(:date).last
      end

      def self.beginning_of_month(time = Time.current)
        time.utc.beginning_of_month
      end

      # We should always use this method to access data for the current month
      # since this will lazily create an entry if it doesn't exist.
      # For example, on the 1st of each month, when we update the usage for a namespace,
      # we will automatically generate new records and reset usage for the current month.
      # This also recalculates any additional minutes based on the previous month usage.
      def self.find_or_create_current(namespace_id:)
        current_usage = unsafe_find_current(namespace_id)
        return current_usage if current_usage

        current_month.for_namespace(namespace_id).new.tap do |new_usage|
          # TODO: Remove in https://gitlab.com/gitlab-org/gitlab/-/issues/350617
          # Avoid cross-database modifications in transaction since
          # recalculation of purchased minutes touches `namespaces` table.
          new_usage.run_after_commit do
            Namespace.find_by_id(namespace_id).try do |namespace|
              Ci::Minutes::Quota.new(namespace).recalculate_remaining_purchased_minutes!
              Ci::Minutes::RefreshCachedDataWorker.perform_async(namespace_id) # rubocop:disable CodeReuse/Worker
            end
          end

          new_usage.save!
        end
      rescue ActiveRecord::RecordNotUnique
        unsafe_find_current(namespace_id)
      end

      def increase_usage(increments)
        increment_params = increments.select { |_attribute, value| value > 0 }
        return if increment_params.empty?

        # The use of `update_counters` ensures we do a SQL update rather than
        # incrementing the counter for the object in memory and then save it.
        # This is better for concurrent updates.
        self.class.update_counters(self, increment_params)
      end

      def self.reset_current_usage(namespace)
        update_current(namespace, amount_used: 0, notification_level: Notification::PERCENTAGES.fetch(:not_set))
      end

      def self.reset_current_notification_level(namespace)
        update_current(namespace, notification_level: Notification::PERCENTAGES.fetch(:not_set))
      end

      def self.update_current(namespace, attributes)
        current_month.for_namespace(namespace).update_all(attributes)
      end
      private_class_method :update_current

      # This is unsafe to use publicly because it would read the data
      # without creating a new record if doesn't exist.
      def self.unsafe_find_current(namespace)
        current_month.for_namespace(namespace).take
      end
      private_class_method :unsafe_find_current

      def total_usage_notified?
        usage_notified?(Notification::PERCENTAGES.fetch(:exceeded))
      end

      # Notification_level is set to 100 (meaning 100% remaining minutes) by default.
      # It is reduced to 30 when the quota available drops below 30%
      # It is reduced to 5 when the quota available drops below 5%
      # It is reduced to 0 when the there are no more minutes available.
      #
      # Legacy tracking of CI minutes (in `namespaces` table) uses 2 attributes instead.
      # We are condensing both into `notification_level` in the new monthly tracking.
      #
      # Until we retire the legacy CI minutes tracking:
      #   * notification_level == 0 is equivalent to last_ci_minutes_notification_at being set
      #   * notification_level between 100 and 0 is equivalent to last_ci_minutes_usage_notification_level
      #     being set
      #   * notification_level == 100 is equivalent to neither of the legacy attributes being set,
      #     meaning that the quota used is still in the bucket 100%-to-30% used.
      def usage_notified?(remaining_percentage)
        notification_level == remaining_percentage
      end
    end
  end
end
