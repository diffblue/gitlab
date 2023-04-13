# frozen_string_literal: true

module Ci
  class SyncReportsToApprovalRulesService < ::BaseService
    include Gitlab::Utils::StrongMemoize

    MEMOIZATIONS = %i(
      policy_configuration
      policy_rule_reports
    ).freeze

    def initialize(pipeline)
      @pipeline = pipeline
    end

    def execute
      sync_license_scanning_rules
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
      ::Security::SyncLicenseScanningRulesService.execute(pipeline)
    end

    def sync_coverage_rules
      return unless pipeline.complete?

      pipeline.update_builds_coverage
      return unless pipeline.coverage.present?

      remove_required_approvals_for(ApprovalMergeRequestRule.code_coverage, merge_requests_approved_coverage)
    end

    def sync_scan_finding
      return if Feature.enabled?(:sync_approval_rules_from_findings, pipeline.project)
      return if policy_rule_reports.empty? && !pipeline.complete?

      remove_required_approvals_for_scan_finding(pipeline.merge_requests_as_head_pipeline.opened)
    end

    def policy_rule_reports
      strong_memoize(:policy_rule_reports) do
        pipeline.security_reports
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

    def remove_required_approvals_for(rules, merge_requests)
      rules
        .for_unmerged_merge_requests(merge_requests)
        .update_all(approvals_required: 0)
    end

    def remove_required_approvals_for_scan_finding(merge_requests)
      merge_requests.each do |merge_request|
        base_reports = merge_request.latest_pipeline_for_target_branch&.security_reports
        scan_finding_rules = merge_request.approval_rules.scan_finding
        selected_rules = scan_finding_rules.reject do |rule|
          violates_default_policy?(rule, base_reports)
        end
        scan_finding_rules.remove_required_approved(selected_rules)
      end
    end

    def policy_configuration
      strong_memoize(:policy_configuration) do
        pipeline.project.security_orchestration_policy_configuration
      end
    end

    def violates_default_policy?(rule, base_reports)
      rule = rule.source_rule if rule.source_rule # to be removed whenever merge request and project levels approval rules are aligned
      policy_rule_reports.violates_default_policy_against?(base_reports, rule.vulnerabilities_allowed, rule.severity_levels, rule.vulnerability_states_for_branch, rule.scanners)
    end
  end
end
