# frozen_string_literal: true

module Security
  class StoreScansService
    def self.execute(pipeline)
      new(pipeline).execute
    end

    def initialize(pipeline)
      @pipeline = pipeline
    end

    def execute
      return if already_purged?

      grouped_report_artifacts.each { |artifacts| StoreGroupedScansService.execute(artifacts) }

      schedule_store_reports_worker
      schedule_scan_security_report_secrets_worker
      sync_findings_to_approval_rules
    end

    private

    attr_reader :pipeline

    delegate :project, to: :pipeline, private: true

    def already_purged?
      pipeline.security_scans.purged.any?
    end

    def grouped_report_artifacts
      pipeline.job_artifacts
              .security_reports
              .group_by(&:file_type)
              .select { |file_type, _| parse_report_file?(file_type) }
              .values
    end

    def parse_report_file?(file_type)
      project.feature_available?(Ci::Build::LICENSED_PARSER_FEATURES.fetch(file_type))
    end

    def schedule_store_reports_worker
      StoreSecurityReportsWorker.perform_async(pipeline.id) if pipeline.default_branch?
    end

    def schedule_scan_security_report_secrets_worker
      ScanSecurityReportSecretsWorker.perform_async(pipeline.id) if revoke_secret_detection_token?
    end

    def revoke_secret_detection_token?
      pipeline.project.public? &&
        ::Gitlab::CurrentSettings.secret_detection_token_revocation_enabled? &&
        secret_detection_scans_found?
    end

    def secret_detection_scans_found?
      pipeline.security_scans.by_scan_types(:secret_detection).any?
    end

    def sync_findings_to_approval_rules
      return unless project.licensed_feature_available?(:security_orchestration_policies) &&
        Feature.enabled?(:sync_approval_rules_from_findings, project)

      Security::ScanResultPolicies::SyncFindingsToApprovalRulesWorker.perform_async(pipeline.id)
    end
  end
end
