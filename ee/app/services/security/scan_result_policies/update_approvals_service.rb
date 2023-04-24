# frozen_string_literal: true

module Security
  module ScanResultPolicies
    class UpdateApprovalsService
      include Gitlab::Utils::StrongMemoize

      attr_reader :pipeline, :merge_request, :target_pipeline, :pipeline_security_findings

      def initialize(merge_request:, pipeline:, pipeline_findings:)
        @pipeline = pipeline
        @merge_request = merge_request
        @target_pipeline = merge_request.latest_pipeline_for_target_branch
        @pipeline_security_findings = pipeline_findings
      end

      def execute
        return if scan_removed?

        unviolated_rules = merge_request.approval_rules.scan_finding.reject do |approval_rule|
          approval_rule = approval_rule.source_rule if approval_rule.source_rule

          violates_approval_rule?(approval_rule)
        end

        ApprovalMergeRequestRule.remove_required_approved(unviolated_rules) if unviolated_rules.any?
      end

      private

      def violates_approval_rule?(approval_rule)
        target_pipeline_uuids = uuids_from_findings(target_pipeline_security_findings, approval_rule)

        return true if findings_count_violated?(approval_rule, target_pipeline_uuids)
        return true if preexisting_findings_count_violated?(approval_rule, target_pipeline_uuids)

        false
      end

      def scan_removed?
        (Array.wrap(target_pipeline&.security_scan_types) - pipeline.security_scan_types).any?
      end

      def target_pipeline_security_findings
        target_pipeline&.security_findings || Security::Finding.none
      end
      strong_memoize_attr :target_pipeline_security_findings

      def findings_count_violated?(approval_rule, target_pipeline_uuids)
        vulnerabilities_allowed = approval_rule.vulnerabilities_allowed

        pipeline_uuids = uuids_from_findings(pipeline_security_findings, approval_rule)
        new_uuids = pipeline_uuids - target_pipeline_uuids

        if only_newly_detected?(approval_rule)
          new_uuids.count > vulnerabilities_allowed
        else
          vulnerabilities_count = vulnerabilities_count_for_uuids(pipeline_uuids, approval_rule)

          if vulnerabilities_count[:exceeded_allowed_count]
            true
          else
            total_count = vulnerabilities_count[:count]
            total_count += new_uuids.count if include_newly_detected?(approval_rule)

            total_count > vulnerabilities_allowed
          end
        end
      end

      def preexisting_findings_count_violated?(approval_rule, target_pipeline_uuids)
        return false if target_pipeline_uuids.empty? || include_newly_detected?(approval_rule)

        vulnerabilities_count = vulnerabilities_count_for_uuids(target_pipeline_uuids, approval_rule)

        vulnerabilities_count[:exceeded_allowed_count]
      end

      def uuids_from_findings(security_findings, approval_rule)
        findings = security_findings.by_severity_levels(approval_rule.severity_levels)
        findings = findings.by_report_types(approval_rule.scanners) if approval_rule.scanners.present?
        findings.fetch_uuids
      end

      def include_newly_detected?(approval_rule)
        approval_rule.vulnerability_states_for_branch.include?(ApprovalProjectRule::NEWLY_DETECTED)
      end

      def only_newly_detected?(approval_rule)
        approval_rule.vulnerability_states_for_branch == [ApprovalProjectRule::NEWLY_DETECTED]
      end

      def vulnerabilities_count_for_uuids(uuids, approval_rule)
        states_without_newly_detected = approval_rule.vulnerability_states_for_branch
          .reject { |state| ApprovalProjectRule::NEWLY_DETECTED == state }

        VulnerabilitiesCountService.new(
          pipeline: pipeline,
          uuids: uuids,
          states: states_without_newly_detected,
          allowed_count: approval_rule.vulnerabilities_allowed
        ).execute
      end
    end
  end
end
