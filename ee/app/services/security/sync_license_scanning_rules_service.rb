# frozen_string_literal: true

module Security
  class SyncLicenseScanningRulesService
    include ::Gitlab::Utils::StrongMemoize

    def self.execute(pipeline)
      new(pipeline).execute
    end

    def initialize(pipeline)
      @pipeline = pipeline
      @scanner = ::Gitlab::LicenseScanning.scanner_for_pipeline(project, pipeline)
    end

    def execute
      return unless scanner.results_available?

      merge_requests = pipeline.merge_requests_as_head_pipeline

      sync_license_finding_rules(merge_requests)
    end

    private

    attr_reader :pipeline, :scanner

    delegate :project, to: :pipeline

    def sync_license_finding_rules(merge_requests)
      merge_requests.each do |merge_request|
        remove_required_license_finding_approval(merge_request)
      end
    end

    def remove_required_license_finding_approval(merge_request)
      license_approval_rules = merge_request
        .approval_rules
        .report_approver
        .license_scanning
        .with_scan_result_policy_read
        .including_scan_result_policy_read

      return if license_approval_rules.empty?

      denied_rules = license_approval_rules.reject { |rule| violates_policy?(merge_request, rule) }
      ApprovalMergeRequestRule.remove_required_approved(denied_rules)
    end

    ## Checks if a policy rule violates the following conditions:
    ##   - If license_states has `newly_detected`, check for newly detected dependency
    ##     with license type violating the policy.
    ##   - If match_on_inclusion is false, any detected licenses that does not match
    ##     the licenses from `license_types` should require approval
    def violates_policy?(merge_request, rule)
      scan_result_policy_read = rule.scan_result_policy_read
      check_denied_licenses = scan_result_policy_read.match_on_inclusion
      target_branch_report = target_branch_report(merge_request)

      license_ids, license_names = licenses_to_check(target_branch_report, scan_result_policy_read)
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

      return true if scan_result_policy_read.newly_detected? &&
        new_dependency_with_denied_license?(target_branch_report, denied_licenses)

      violates_license_policy
    end

    def licenses_to_check(target_branch_report, scan_result_policy_read)
      only_newly_detected = scan_result_policy_read.license_states == [ApprovalProjectRule::NEWLY_DETECTED]

      if only_newly_detected
        diff = target_branch_report.diff_with(report)
        license_names = diff[:added].map(&:name)
        license_ids = diff[:added].filter_map(&:id)
      elsif scan_result_policy_read.newly_detected?
        license_names = report.license_names
        license_ids = report.licenses.filter_map(&:id)
      else
        license_names = target_branch_report.license_names
        license_ids = target_branch_report.licenses.filter_map(&:id)
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

    def new_dependency_with_denied_license?(target_branch_report, denied_licenses)
      dependencies_with_denied_licenses = report.licenses
        .select { |license| denied_licenses.include?(license.name) || denied_licenses.include?(license.id) }
        .flat_map(&:dependencies).map(&:name)

      (dependencies_with_denied_licenses & new_dependency_names(target_branch_report)).present?
    end

    def target_branch_report(merge_request)
      ::Gitlab::LicenseScanning.scanner_for_pipeline(project, merge_request.latest_pipeline_for_target_branch).report
    end

    def new_dependency_names(target_branch_report)
      report.dependency_names - target_branch_report.dependency_names
    end

    def report
      scanner.report
    end
    strong_memoize_attr :report

    def license_names_from_report
      report.license_names.concat(report.licenses.filter_map(&:id)).compact.uniq
    end
    strong_memoize_attr :license_names_from_report
  end
end
