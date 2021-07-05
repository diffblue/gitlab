# frozen_string_literal: true

module Analytics
  module DevopsAdoption
    # Updates all pending snapshots for given enabled_namespace (from previous month)
    class CreateSnapshotWorker
      include ApplicationWorker

      data_consistency :always

      sidekiq_options retry: 3

      feature_category :devops_reports
      idempotent!
      tags :exclude_from_kubernetes

      def perform(enabled_namespace_id)
        enabled_namespace = EnabledNamespace.find(enabled_namespace_id)

        pending_ranges(enabled_namespace).each do |range_end|
          Snapshots::CalculateAndSaveService.new(enabled_namespace: enabled_namespace, range_end: range_end).execute
        end
      end

      private

      # rubocop: disable CodeReuse/ActiveRecord
      def pending_ranges(enabled_namespace)
        end_times = enabled_namespace.snapshots.not_finalized.pluck(:end_time)

        prev_month = Time.current.last_month.end_of_month
        unless prev_month.to_date.in?(end_times.map(&:to_date)) || enabled_namespace.snapshots.for_month(prev_month).exists?
          end_times << prev_month
        end

        end_times
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
