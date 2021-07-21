# frozen_string_literal: true

# Worker for storing security reports into the database.
#
class StoreSecurityReportsWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3
  include SecurityScansQueue

  worker_resource_boundary :cpu

  def perform(pipeline_id)
    Ci::Pipeline.find(pipeline_id).try do |pipeline|
      break unless pipeline.project.can_store_security_reports?

      ::Security::StoreReportsService.new(pipeline).execute

      if revoke_secret_detection_token?(pipeline)
        logger.info "StoreSecurityReportsWorker: token revocation started for pipeline: #{pipeline.id}"
        ::ScanSecurityReportSecretsWorker.perform_async(pipeline.id)
      else
        logger.info "StoreSecurityReportsWorker: did not revoke token for pipeline: #{pipeline.id}"
      end
    end
  end

  private

  def revoke_secret_detection_token?(pipeline)
    pipeline.present? &&
      pipeline.project.public? &&
      ::Gitlab::CurrentSettings.secret_detection_token_revocation_enabled? &&
      secret_detection_vulnerability_found?(pipeline)
  end

  def secret_detection_vulnerability_found?(pipeline)
    pipeline.vulnerability_findings.secret_detection.any?
  end
end
