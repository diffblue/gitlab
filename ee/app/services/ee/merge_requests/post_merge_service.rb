# frozen_string_literal: true

module EE
  module MergeRequests
    module PostMergeService
      extend ::Gitlab::Utils::Override

      override :execute
      def execute(merge_request)
        super
        ApprovalRules::FinalizeService.new(merge_request).execute

        target_project = merge_request.target_project
        if compliance_violations_enabled?(target_project.namespace)
          ComplianceManagement::MergeRequests::ComplianceViolationsWorker.perform_async(merge_request.id)
        end

        audit_approval_rules(merge_request)
        sync_security_scan_orchestration_policies(target_project)
        trigger_blocked_merge_requests_merge_status_updated(merge_request)
      end

      private

      def compliance_violations_enabled?(group)
        group.licensed_feature_available?(:group_level_compliance_dashboard)
      end

      def audit_approval_rules(merge_request)
        invalid_rules = merge_request.invalid_approvers_rules

        track_invalid_approvers(merge_request) if invalid_rules.present?

        invalid_rules.each do |rule|
          audit_invalid_rule(merge_request, rule)
        end
      end

      def track_invalid_approvers(merge_request)
        ::Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter
          .track_invalid_approvers(merge_request: merge_request)
      end

      def audit_invalid_rule(merge_request, rule)
        audit_context = {
          name: 'merge_request_invalid_approver_rules',
          author: merge_request.author,
          scope: project,
          target: merge_request,
          message: 'Invalid merge request approver rules',
          target_details: {
            title: merge_request.title,
            iid: merge_request.iid,
            id: merge_request.id,
            rule_type: rule.rule_type,
            rule_name: rule.name
          }
        }

        ::Gitlab::Audit::Auditor.audit(audit_context)
      end

      def sync_security_scan_orchestration_policies(project)
        return unless project.licensed_feature_available?(:security_orchestration_policies)

        Security::OrchestrationPolicyConfiguration
          .for_management_project(project)
          .each do |configuration|
          Security::SyncScanPoliciesWorker.perform_async(configuration.id)
        end
      end

      def trigger_blocked_merge_requests_merge_status_updated(merge_request)
        merge_request.blocked_merge_requests.find_each do |blocked_mr|
          ::GraphqlTriggers.merge_request_merge_status_updated(blocked_mr)
        end
      end
    end
  end
end
