# frozen_string_literal: true

module Analytics
  module DevopsAdoption
    # Schedules update of snapshots for all enabled_namespaces
    class CreateAllSnapshotsWorker
      include ApplicationWorker

      data_consistency :always

      sidekiq_options retry: 3
      # This worker does not perform work scoped to a context
      include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

      feature_category :devops_reports
      tags :exclude_from_kubernetes
      idempotent!

      WORKERS_GAP = 5.seconds

      def perform
        each_pending_namespace_id do |enabled_namespace_id, index|
          CreateSnapshotWorker.perform_in(index * WORKERS_GAP, enabled_namespace_id)
        end
      end

      private

      def each_pending_namespace_id
        index = 0
        ::Analytics::DevopsAdoption::EnabledNamespace.pending_calculation.each_batch(of: 100) do |batch|
          batch.pluck_primary_key.each do |id|
            yield(id, index)
            index += 1
          end
        end
      end
    end
  end
end
