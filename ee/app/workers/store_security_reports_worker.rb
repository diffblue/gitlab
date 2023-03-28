# frozen_string_literal: true

# Worker for storing security reports into the database.
#
class StoreSecurityReportsWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3
  include SecurityScansQueue

  feature_category :vulnerability_management

  worker_resource_boundary :cpu

  def perform(pipeline_id)
    Ci::Pipeline.find_by_id(pipeline_id).try do |pipeline|
      break unless pipeline.project.can_store_security_reports?

      ::Security::Ingestion::IngestReportsService.execute(pipeline)
    end
  end
end
