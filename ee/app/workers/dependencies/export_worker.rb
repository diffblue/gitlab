# frozen_string_literal: true

module Dependencies
  class ExportWorker
    include ApplicationWorker
    include ::Gitlab::ExclusiveLeaseHelpers

    LEASE_TTL = 1.hour
    LEASE_NAMESPACE = "dependencies_export_worker"

    data_consistency :always

    sidekiq_options retry: true

    idempotent!
    feature_category :dependency_management

    sidekiq_retries_exhausted do |job|
      Dependencies::DependencyListExport.find_by_id(job['args'].last).failed!
    end

    def perform(dependency_list_export_id)
      dependency_list_export = Dependencies::DependencyListExport.find(dependency_list_export_id)

      Dependencies::ExportService.execute(dependency_list_export)
    end
  end
end
