# frozen_string_literal: true

module IncidentManagement
  class IncidentSlaExceededCheckWorker
    include ApplicationWorker

    data_consistency :always
    worker_resource_boundary :cpu

    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

    idempotent!
    feature_category :incident_management

    def perform
      iterator = Gitlab::Pagination::Keyset::Iterator.new(scope: IssuableSla.exceeded)

      iterator.each_batch(of: 1000) do |records|
        records.each do |incident_sla|
          ApplyIncidentSlaExceededLabelWorker.perform_async(incident_sla.issue_id)
        end
      end
    end
  end
end
