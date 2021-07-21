# frozen_string_literal: true

module IncidentManagement
  module PendingEscalations
    class ScheduleCheckCronWorker
      include ApplicationWorker

      data_consistency :always
      # This worker does not perform work scoped to a context
      include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

      idempotent!
      feature_category :incident_management

      def perform
        ::IncidentManagement::PendingEscalations::Alert.processable.each_batch do |relation|
          args = relation.pluck(:id).map { |id| [id] } # rubocop:disable  CodeReuse/ActiveRecord
          ::IncidentManagement::PendingEscalations::AlertCheckWorker.bulk_perform_async(args)  # rubocop:disable Scalability/BulkPerformWithContext
        end
      end
    end
  end
end
