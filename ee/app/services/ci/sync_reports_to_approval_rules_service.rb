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
        project_vulnerability_rules ? pipeline.security_reports(report_types: project_vulnerability_rules) : []
      end
    end

    def project_vulnerability_rules
      strong_memoize(:project_vulnerability_rules) do
        pipeline.project.approval_rules.vulnerability_reports.first&.scanners
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
        reports.present? && reports.violates_default_policy_against?(merge_request.base_pipeline&.security_reports)
      end
    end

    def remove_required_approvals_for(rules, merge_requests)
      rules
        .for_unmerged_merge_requests(merge_requests)
        .update_all(approvals_required: 0)
    end
  end
end
