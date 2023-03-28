# frozen_string_literal: true

# Worker for triggering events subject to secret_detection security reports
#
class ScanSecurityReportSecretsWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  queue_namespace :security_scans
  feature_category :secret_detection

  worker_resource_boundary :cpu

  sidekiq_options retry: 17

  worker_has_external_dependencies!
  idempotent!

  ScanSecurityReportSecretsWorkerError = Class.new(StandardError)

  DEFAULT_BATCH_SIZE = 100

  def perform(pipeline_id)
    pipeline = Ci::Pipeline.find_by_id(pipeline_id)
    return unless pipeline

    keys = revocable_keys(pipeline)

    if keys.present?
      executed_result = Security::TokenRevocationService.new(revocable_keys: keys).execute

      raise ScanSecurityReportSecretsWorkerError, executed_result[:message] if executed_result[:status] == :error
    end
  end

  private

  def revocable_keys(pipeline)
    keys = []

    pipeline.security_findings.by_report_types(:secret_detection).each_batch(of: DEFAULT_BATCH_SIZE) do |relation|
      relation.each do |security_finding|
        keys << {
          type: revocation_type(security_finding),
          token: security_finding.raw_source_code_extract,
          location: security_finding.present.location_link_with_raw_path,
          vulnerability: security_finding.vulnerability
        }
      end
    end

    keys
  end

  def revocation_type(security_finding)
    identifier = security_finding.identifiers.first

    (identifier[:external_type] + '_' + identifier[:external_id].tr(' ', '_')).downcase
  end
end
