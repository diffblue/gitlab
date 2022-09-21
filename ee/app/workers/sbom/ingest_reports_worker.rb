# frozen_string_literal: true

module Sbom
  class IngestReportsWorker
    include ApplicationWorker

    idempotent!

    data_consistency :always

    worker_resource_boundary :cpu
    queue_namespace :sbom_reports
    feature_category :dependency_management

    def perform(pipeline_id)
      ::Ci::Pipeline.find_by_id(pipeline_id).try do |pipeline|
        break unless pipeline.can_ingest_sbom_reports?

        ::Sbom::Ingestion::IngestReportsService.execute(pipeline)
      end
    end
  end
end
