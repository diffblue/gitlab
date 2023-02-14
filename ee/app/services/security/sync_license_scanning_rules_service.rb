# frozen_string_literal: true

module Security
  class SyncLicenseScanningRulesService
    include ::Gitlab::Utils::StrongMemoize

    def self.execute(pipeline)
      new(pipeline).execute
    end

    def initialize(pipeline)
      @pipeline = pipeline
    end

    def execute
      return if report.empty? && !pipeline.complete?

      merge_requests = pipeline.merge_requests_as_head_pipeline

      sync_license_check_rule(merge_requests)
      sync_license_finding_rules(merge_requests) if Feature.enabled?(:license_scanning_policies, project)
    end

    private

    attr_reader :pipeline

    delegate :project, to: :pipeline

    def sync_license_check_rule(merge_requests)
      return if report.violates?(project.software_license_policies.without_scan_result_policy_read)

      ApprovalMergeRequestRule
        .report_approver
        .license_scanning
        .without_scan_result_policy_read
        .for_unmerged_merge_requests(merge_requests)
        .update_all(approvals_required: 0)
    end

    def sync_license_finding_rules(merge_requests)
      license_approval_rules = ApprovalMergeRequestRule
        .report_approver
        .license_scanning
        .with_scan_result_policy_read
        .including_scan_result_policy_read
        .for_unmerged_merge_requests(merge_requests)

      return if license_approval_rules.empty?

      denied_rules = license_approval_rules.reject { |rule| violates_policy?(rule) }
      ApprovalMergeRequestRule.remove_required_approved(denied_rules)
    end

    ## Checks if a policy rule violates the following conditions:
    ##   - If license_states has `newly_detected`, check for newly detected dependency
    ##     even if does not violate license rules.
    ##   - If match_on_inclusion is false, any detected licenses that does not match
    ##     the licenses from `license_types` should require approval
    def violates_policy?(rule)
      scan_result_policy_read = rule.scan_result_policy_read
      check_denied_licenses = scan_result_policy_read.match_on_inclusion
      newly_detected = scan_result_policy_read.license_states.include?(ApprovalProjectRule::NEWLY_DETECTED)

      license_ids, license_names = licenses_to_check(scan_result_policy_read)
      license_policies = project
        .software_license_policies
        .including_license
        .for_scan_result_policy_read(scan_result_policy_read.id)

      violates_license_policy = if check_denied_licenses
                                  report.violates_for_licenses?(license_policies, license_ids, license_names)
                                else
                                  (license_names - license_policies.map(&:name)).present?
                                end

      return new_dependency_found || violates_license_policy if newly_detected

      violates_license_policy
    end

    def licenses_to_check(scan_result_policy_read)
      only_newly_detected = scan_result_policy_read.license_states == [ApprovalProjectRule::NEWLY_DETECTED]

      if only_newly_detected
        diff = default_branch_report.diff_with(report)
        license_names = diff[:added].map(&:name)
        license_ids = diff[:added].filter_map(&:id)
      else
        license_names = report.license_names
        license_ids = report.licenses.filter_map(&:id)
      end

      [license_ids, license_names]
    end

    def report
      project.license_compliance(pipeline).license_scanning_report
    end
    strong_memoize_attr :report

    def default_branch_report
      project.license_compliance.license_scanning_report
    end
    strong_memoize_attr :default_branch_report

    def new_dependency_found
      (report.dependency_names - default_branch_report.dependency_names).present?
    end
    strong_memoize_attr :new_dependency_found
  end
end
