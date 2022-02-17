# frozen_string_literal: true

module Ci
  class SyncReportsToApprovalRulesService < ::BaseService
    include Gitlab::Utils::StrongMemoize

    MEMOIZATIONS = %i(
      policy_configuration
      policy_rule_reports
      policy_rule_scanners
      project_rule_scanners
      project_rule_severity_levels
      project_rule_vulnerabilities_allowed
      project_rule_vulnerability_states
      project_vulnerability_report
      reports
    ).freeze

    def initialize(pipeline)
      @pipeline = pipeline
    end

    def execute
      sync_license_scanning_rules
      sync_vulnerability_rules
      sync_coverage_rules
      sync_scan_finding
      success
    rescue StandardError => error
      payload = {
        pipeline: pipeline&.to_param,
        source: "#{__FILE__}:#{__LINE__}"
      }

      Gitlab::ExceptionLogFormatter.format!(error, payload)
      log_error(payload)
      error("Failed to update approval rules")
    ensure
      MEMOIZATIONS.each do |memoization|
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
      return unless pipeline.coverage.present?

      remove_required_approvals_for(ApprovalMergeRequestRule.code_coverage, merge_requests_approved_coverage)
    end

    def sync_scan_finding
      return if ::Feature.disabled?(:scan_result_policy, pipeline.project, default_enabled: :yaml)
      return if policy_rule_reports.empty? && !pipeline.complete?

      remove_required_approvals_for_scan_finding(pipeline.merge_requests_as_head_pipeline.opened)
    end

    def reports
      strong_memoize(:reports) do
        project_rule_scanners ? pipeline.security_reports(report_types: project_rule_scanners) : []
      end
    end

    def policy_rule_reports
      strong_memoize(:policy_rule_reports) do
        policy_rule_scanners ? pipeline.security_reports(report_types: policy_rule_scanners) : []
      end
    end

    def project_rule_scanners
      strong_memoize(:project_rule_scanners) do
        project_vulnerability_report&.scanners
      end
    end

    def policy_rule_scanners
      strong_memoize(:policy_rule_scanners) do
        policy_configuration&.uniq_scanners
      end
    end

    def project_rule_vulnerabilities_allowed
      strong_memoize(:project_rule_vulnerabilities_allowed) do
        project_vulnerability_report&.vulnerabilities_allowed
      end
    end

    def merge_requests_approved_coverage
      pipeline.merge_requests_as_head_pipeline.reject do |merge_request|
        require_coverage_approval?(merge_request)
      end
    end

    def require_coverage_approval?(merge_request)
      base_pipeline = merge_request.base_pipeline

      # if base pipeline is missing we just default to not require approval.
      return false unless base_pipeline.present?

      return true unless base_pipeline.coverage.present?

      pipeline.coverage < base_pipeline.coverage
    end

    def merge_requests_approved_security_reports
      pipeline.merge_requests_as_head_pipeline.reject do |merge_request|
        reports.present? && reports.violates_default_policy_against?(merge_request.base_pipeline&.security_reports, project_rule_vulnerabilities_allowed, project_rule_severity_levels, project_rule_vulnerability_states)
      end
    end

    def remove_required_approvals_for(rules, merge_requests)
      rules
        .for_unmerged_merge_requests(merge_requests)
        .update_all(approvals_required: 0)
    end

    def remove_required_approvals_for_scan_finding(merge_requests)
      merge_requests.each do |merge_request|
        base_reports = merge_request.base_pipeline&.security_reports
        scan_finding_rules = merge_request.approval_rules.scan_finding
        selected_rules = scan_finding_rules.reject do |rule|
          violates_default_policy?(rule.source_rule, base_reports)
        end
        scan_finding_rules.remove_required_approved(selected_rules)
      end
    end

    def project_rule_severity_levels
      strong_memoize(:project_rule_severity_levels) do
        project_vulnerability_report&.severity_levels
      end
    end

    def project_rule_vulnerability_states
      strong_memoize(:project_rule_vulnerability_states) do
        project_vulnerability_report&.vulnerability_states_for_branch
      end
    end

    def project_vulnerability_report
      strong_memoize(:project_vulnerability_report) do
        pipeline.project.vulnerability_report_rule
      end
    end

    def policy_configuration
      strong_memoize(:policy_configuration) do
        pipeline.project.security_orchestration_policy_configuration
      end
    end

    def violates_default_policy?(source_rule, base_reports)
      policy_rule_reports.violates_default_policy_against?(base_reports, source_rule.vulnerabilities_allowed, source_rule.severity_levels, source_rule.vulnerability_states_for_branch, source_rule.scanners)
    end
  end
end
