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

        return unless target_project.licensed_feature_available?(:security_orchestration_policies)

        Security::OrchestrationPolicyConfiguration
          .for_management_project(target_project)
          .each do |configuration|
          Security::SyncScanPoliciesWorker.perform_async(configuration.id)
        end
      end

      private

      def compliance_violations_enabled?(group)
        group.licensed_feature_available?(:group_level_compliance_dashboard)
      end

      def audit_approval_rules(merge_request)
        merge_request.wrapped_approval_rules.each do |rule|
          next if rule.any_approver?
          next unless rule.approvers.empty?

          if rule.code_owner?
            audit_invalid_rule(merge_request, rule) if rule.branch_requires_code_owner_approval?
          elsif rule.approvals_required > 0
            audit_invalid_rule(merge_request, rule)
          end
        end
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
    end
  end
end
