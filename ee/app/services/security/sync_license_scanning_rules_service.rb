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
    ##     with license type violating the policy.
    ##   - If match_on_inclusion is false, any detected licenses that does not match
    ##     the licenses from `license_types` should require approval
    def violates_policy?(rule)
      scan_result_policy_read = rule.scan_result_policy_read
      check_denied_licenses = scan_result_policy_read.match_on_inclusion

      license_ids, license_names = licenses_to_check(scan_result_policy_read)
      license_policies = project
        .software_license_policies
        .including_license
        .for_scan_result_policy_read(scan_result_policy_read.id)

      license_names_from_policy = license_names_from_policy(license_policies)
      if check_denied_licenses
        denied_licenses = license_names_from_policy
        violates_license_policy = report.violates_for_licenses?(license_policies, license_ids, license_names)
      else
        # when match_on_inclusion is false, only allowed licenses are mentioned in policy
        denied_licenses = (license_names_from_report - license_names_from_policy).uniq
        license_names_from_ids = license_names_from_ids(license_ids, license_names)
        violates_license_policy = (license_names_from_ids - license_names_from_policy).present?
      end

      return true if scan_result_policy_read.newly_detected? && new_dependency_with_denied_license?(denied_licenses)

      violates_license_policy
    end

    def licenses_to_check(scan_result_policy_read)
      only_newly_detected = scan_result_policy_read.license_states == [ApprovalProjectRule::NEWLY_DETECTED]

      if only_newly_detected
        diff = default_branch_report.diff_with(report)
        license_names = diff[:added].map(&:name)
        license_ids = diff[:added].filter_map(&:id)
      elsif scan_result_policy_read.newly_detected?
        license_names = report.license_names
        license_ids = report.licenses.filter_map(&:id)
      else
        license_names = default_branch_report.license_names
        license_ids = default_branch_report.licenses.filter_map(&:id)
      end

      [license_ids, license_names]
    end

    def license_names_from_policy(license_policies)
      ids = license_policies.map(&:spdx_identifier)
      names = license_policies.map(&:name)

      ids.concat(names).compact
    end

    def license_names_from_ids(ids, names)
      ids.concat(names).compact.uniq
    end

    def new_dependency_with_denied_license?(denied_licenses)
      dependencies_with_denied_licenses = report.licenses
        .select { |license| denied_licenses.include?(license.name) || denied_licenses.include?(license.id) }
        .flat_map(&:dependencies).map(&:name)

      (dependencies_with_denied_licenses & new_dependency_names).present?
    end

    def report
      project.license_compliance(pipeline).license_scanning_report
    end
    strong_memoize_attr :report

    def default_branch_report
      project.license_compliance.license_scanning_report
    end
    strong_memoize_attr :default_branch_report

    def new_dependency_names
      report.dependency_names - default_branch_report.dependency_names
    end
    strong_memoize_attr :new_dependency_names

    def license_names_from_report
      report.license_names.concat(report.licenses.filter_map(&:id)).compact.uniq
    end
    strong_memoize_attr :license_names_from_report
  end
end
