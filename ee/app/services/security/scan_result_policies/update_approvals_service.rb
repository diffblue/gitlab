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
        approval_rules = merge_request.approval_rules.scan_finding
        return if approval_rules.empty?

        log_update_approval_rule('Evaluating MR approval rules from scan result policies',
          merge_request_id: merge_request.id,
          pipeline_ids: multi_pipeline_scan_result_policies_enabled? ? related_pipeline_ids : pipeline.id,
          target_pipeline_ids:
            multi_pipeline_scan_result_policies_enabled? ? related_target_pipeline_ids : target_pipeline.id
        )

        violated_rules, unviolated_rules = partition_rules(approval_rules)

        ApprovalMergeRequestRule.remove_required_approved(unviolated_rules) if unviolated_rules.any?
        generate_policy_bot_comment(violated_rules.any?)
      end

      private

      delegate :project, to: :pipeline

      def partition_rules(approval_rules)
        approval_rules.partition do |approval_rule|
          approval_rule = approval_rule.source_rule if approval_rule.source_rule

          if scan_removed?(approval_rule)
            log_update_approval_rule(
              'Updating MR approval rule',
              reason: 'Scanner removed by MR', approval_rule_id: approval_rule.id
            )

            next true
          end

          approval_rule_violated = violates_approval_rule?(approval_rule)
          if approval_rule_violated
            log_update_approval_rule(
              'Updating MR approval rule',
              reason: 'scan_finding rule violated', approval_rule_id: approval_rule.id
            )
          end

          approval_rule_violated
        end
      end

      def log_update_approval_rule(message, **attributes)
        Gitlab::AppJsonLogger.info(message: message, **attributes)
      end

      def violates_approval_rule?(approval_rule)
        target_pipeline_uuids = target_pipeline_findings_uuids(approval_rule)

        return true if findings_count_violated?(approval_rule, target_pipeline_uuids)
        return true if preexisting_findings_count_violated?(approval_rule, target_pipeline_uuids)

        false
      end

      def scan_removed?(approval_rule)
        scan_types_diff = target_pipeline_security_scan_types - pipeline_security_scan_types
        scanners = approval_rule.scanners

        return scan_types_diff.any? if scanners.empty?

        (scan_types_diff & scanners).any?
      end

      def pipeline_security_scan_types
        return security_scan_types(related_pipeline_ids) if multi_pipeline_scan_result_policies_enabled?

        pipeline.security_scan_types
      end
      strong_memoize_attr :pipeline_security_scan_types

      def target_pipeline_security_scan_types
        return security_scan_types(related_target_pipeline_ids) if multi_pipeline_scan_result_policies_enabled?

        target_pipeline&.security_scan_types || []
      end
      strong_memoize_attr :target_pipeline_security_scan_types

      def generate_policy_bot_comment(violated_policy)
        return if Feature.disabled?(:security_policy_approval_notification, pipeline.project)

        Security::GeneratePolicyViolationCommentWorker.perform_async(
          merge_request.id,
          { 'report_type' => Security::ScanResultPolicies::PolicyViolationComment::REPORT_TYPES[:scan_finding],
            'violated_policy' => violated_policy }
        )
      end

      def target_pipeline
        merge_request.latest_finished_target_branch_pipeline_for_scan_result_policy
      end
      strong_memoize_attr :target_pipeline

      def findings_count_violated?(approval_rule, target_pipeline_uuids)
        vulnerabilities_allowed = approval_rule.vulnerabilities_allowed

        pipeline_uuids = pipeline_findings_uuids(approval_rule)
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

      def related_pipeline_sources
        Enums::Ci::Pipeline.ci_and_security_orchestration_sources.values
      end

      def security_scan_types(pipeline_ids)
        Security::Scan.by_pipeline_ids(pipeline_ids).distinct_scan_types
      end

      def related_target_pipeline_ids
        return [] unless target_pipeline

        Security::RelatedPipelinesFinder.new(target_pipeline, { sources: related_pipeline_sources }).execute
      end
      strong_memoize_attr :related_target_pipeline_ids

      def related_pipeline_ids
        Security::RelatedPipelinesFinder.new(pipeline, { sources: related_pipeline_sources }).execute
      end
      strong_memoize_attr :related_pipeline_ids

      def multi_pipeline_scan_result_policies_enabled?
        Feature.enabled?(:multi_pipeline_scan_result_policies, pipeline.project)
      end
      strong_memoize_attr :multi_pipeline_scan_result_policies_enabled?

      def target_pipeline_findings_uuids(approval_rule)
        pipeline_ids = related_target_pipeline_ids if multi_pipeline_scan_result_policies_enabled?
        findings_uuids(target_pipeline, approval_rule, pipeline_ids)
      end

      def pipeline_findings_uuids(approval_rule)
        pipeline_ids = related_pipeline_ids if multi_pipeline_scan_result_policies_enabled?
        findings_uuids(pipeline, approval_rule, pipeline_ids, true)
      end

      def findings_uuids(pipeline, approval_rule, pipeline_ids, check_dismissed = false)
        finder_params = {
          vulnerability_states: approval_rule.vulnerability_states_for_branch,
          severity_levels: approval_rule.severity_levels,
          scanners: approval_rule.scanners,
          check_dismissed: check_dismissed
        }

        finder_params[:related_pipeline_ids] = pipeline_ids if pipeline_ids.present?

        Security::ScanResultPolicies::FindingsFinder
          .new(project, pipeline, finder_params)
          .execute
          .distinct_uuids
      end

      def vulnerabilities_count_for_uuids(uuids, approval_rule)
        VulnerabilitiesCountService.new(
          project: project,
          uuids: uuids,
          states: states_without_newly_detected(approval_rule.vulnerability_states),
          allowed_count: approval_rule.vulnerabilities_allowed,
          vulnerability_age: approval_rule.scan_result_policy_read&.vulnerability_age
        ).execute
      end

      def states_without_newly_detected(vulnerability_states)
        vulnerability_states.reject { |state| ApprovalProjectRule::NEWLY_DETECTED_STATUSES.include?(state) }
      end
    end
  end
end
