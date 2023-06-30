# frozen_string_literal: true

module Security
  module ScanResultPolicies
    class UpdateApprovalsService
      include Gitlab::Utils::StrongMemoize

      attr_reader :pipeline, :merge_request

      def initialize(merge_request:, pipeline:)
        @pipeline = pipeline
        @merge_request = merge_request
      end

      def execute
        return if Feature.disabled?(:security_policy_approval_notification, pipeline.project) && scan_removed?

        approval_rules = merge_request.approval_rules.scan_finding
        return if approval_rules.empty?

        violated_rules, unviolated_rules = approval_rules.partition do |approval_rule|
          approval_rule = approval_rule.source_rule if approval_rule.source_rule

          violates_approval_rule?(approval_rule)
        end

        ApprovalMergeRequestRule.remove_required_approved(unviolated_rules) if unviolated_rules.any? && !scan_removed?
        generate_policy_bot_comment(violated_rules.any? || scan_removed?)
      end

      private

      delegate :project, to: :pipeline

      def violates_approval_rule?(approval_rule)
        target_pipeline_uuids = findings_uuids(target_pipeline, approval_rule)

        return true if findings_count_violated?(approval_rule, target_pipeline_uuids)
        return true if preexisting_findings_count_violated?(approval_rule, target_pipeline_uuids)

        false
      end

      def scan_removed?
        (Array.wrap(target_pipeline&.security_scan_types) - pipeline.security_scan_types).any?
      end
      strong_memoize_attr :scan_removed?

      def generate_policy_bot_comment(violated_policy)
        return if Feature.disabled?(:security_policy_approval_notification, pipeline.project)

        Security::GeneratePolicyViolationCommentWorker.perform_async(merge_request.id, violated_policy)
      end

      def target_pipeline
        merge_request.latest_finished_target_branch_pipeline_for_scan_result_policy
      end
      strong_memoize_attr :target_pipeline

      def findings_count_violated?(approval_rule, target_pipeline_uuids)
        vulnerabilities_allowed = approval_rule.vulnerabilities_allowed

        pipeline_uuids = findings_uuids(pipeline, approval_rule, true)
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

      def include_newly_detected?(approval_rule)
        (approval_rule.vulnerability_states_for_branch & ApprovalProjectRule::NEWLY_DETECTED_STATUSES).any?
      end

      def only_newly_detected?(approval_rule)
        approval_rule.vulnerability_states_for_branch.all? do |state|
          state.in?(ApprovalProjectRule::NEWLY_DETECTED_STATUSES)
        end
      end

      def findings_uuids(pipeline, approval_rule, check_dismissed = false)
        Security::ScanResultPolicies::FindingsFinder.new(pipeline, {
          vulnerability_states: approval_rule.vulnerability_states_for_branch,
          severity_levels: approval_rule.severity_levels,
          scanners: approval_rule.scanners,
          check_dismissed: check_dismissed
        }).execute.fetch_uuids
      end

      def vulnerabilities_count_for_uuids(uuids, approval_rule)
        VulnerabilitiesCountService.new(
          project: project,
          uuids: uuids,
          states: states_without_newly_detected(approval_rule.vulnerability_states),
          allowed_count: approval_rule.vulnerabilities_allowed
        ).execute
      end

      def states_without_newly_detected(vulnerability_states)
        vulnerability_states.reject { |state| ApprovalProjectRule::NEWLY_DETECTED_STATUSES.include?(state) }
      end
    end
  end
end
