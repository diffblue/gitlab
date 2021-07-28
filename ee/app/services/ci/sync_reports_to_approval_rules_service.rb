# frozen_string_literal: true

module Ci
  class SyncReportsToApprovalRulesService < ::BaseService
    include Gitlab::Utils::StrongMemoize

    def initialize(pipeline)
      @pipeline = pipeline
    end

    def execute
      sync_license_scanning_rules
      sync_vulnerability_rules
      sync_coverage_rules
      success
    rescue StandardError => error
      log_error(
        pipeline: pipeline&.to_param,
        error: error.class.name,
        message: error.message,
        source: "#{__FILE__}:#{__LINE__}",
        backtrace: error.backtrace
      )
      error("Failed to update approval rules")
    ensure
      [:project_rule_vulnerabilities_allowed, :project_rule_scanners, :project_rule_severity_levels, :project_vulnerability_report, :reports].each do |memoization|
        clear_memoization(memoization)
      end
    end

    private

    attr_reader :pipeline

    def sync_license_scanning_rules
      project = pipeline.project
      report = pipeline.license_scanning_report
      return if report.empty? && !pipeline.complete?
      return if report.violates?(project.software_license_policies)

      remove_required_approvals_for(ApprovalMergeRequestRule.report_approver.license_scanning,
                                    pipeline.merge_requests_as_head_pipeline)
    end

    def sync_vulnerability_rules
      # If we have some reports, then we want to sync them early;
      # If we don't have reports, then we should wait until pipeline stops.
      return if reports.empty? && !pipeline.complete?

      remove_required_approvals_for(ApprovalMergeRequestRule.vulnerability_report, merge_requests_approved_security_reports)
    end

    def sync_coverage_rules
      return unless pipeline.complete?

      pipeline.update_builds_coverage
      remove_required_approvals_for(ApprovalMergeRequestRule.code_coverage, merge_requests_approved_coverage)
    end

    def reports
      strong_memoize(:reports) do
        project_rule_scanners ? pipeline.security_reports(report_types: project_rule_scanners) : []
      end
    end

    def project_rule_scanners
      strong_memoize(:project_rule_scanners) do
        project_vulnerability_report&.scanners
      end
    end

    def project_rule_vulnerabilities_allowed
      strong_memoize(:project_rule_vulnerabilities_allowed) do
        project_vulnerability_report&.vulnerabilities_allowed
      end
    end

    def merge_requests_approved_coverage
      pipeline.merge_requests_as_head_pipeline.reject do |merge_request|
        base_pipeline = merge_request.base_pipeline

        # if base pipeline is missing we just default to not require approval.
        pipeline.coverage < base_pipeline.coverage if base_pipeline.present?
      end
    end

    def merge_requests_approved_security_reports
      pipeline.merge_requests_as_head_pipeline.reject do |merge_request|
        reports.present? && reports.violates_default_policy_against?(merge_request.base_pipeline&.security_reports, project_rule_vulnerabilities_allowed, project_rule_severity_levels)
      end
    end

    def remove_required_approvals_for(rules, merge_requests)
      rules
        .for_unmerged_merge_requests(merge_requests)
        .update_all(approvals_required: 0)
    end

    def project_rule_severity_levels
      strong_memoize(:project_rule_severity_levels) do
        project_vulnerability_report&.severity_levels
      end
    end

    def project_vulnerability_report
      strong_memoize(:project_vulnerability_report) do
        pipeline.project.vulnerability_report_rule
      end
    end
  end
end
