# frozen_string_literal: true

module Security
  module SecurityOrchestrationPolicies
    class ProcessScanResultPolicyService
      MAX_LENGTH = 25

      def initialize(policy_configuration:, policy:)
        @policy_configuration = policy_configuration
        @policy = policy
        @project = policy_configuration.project
        @author = policy_configuration.policy_last_updated_by
      end

      def execute
        return if ::Feature.disabled?(:scan_result_policy, project)

        create_new_approval_rules
      end

      private

      attr_reader :policy_configuration, :policy, :project, :author

      def create_new_approval_rules
        action_info = policy[:actions].find { |action| action[:type] == Security::ScanResultPolicy::REQUIRE_APPROVAL }
        return unless action_info

        policy[:rules].each_with_index do |rule, rule_index|
          next if rule[:type] != Security::ScanResultPolicy::SCAN_FINDING

          ::ApprovalRules::CreateService.new(project, author, rule_params(rule, rule_index, action_info)).execute
        end
      end

      def rule_params(rule, rule_index, action_info)
        {
          approvals_required: action_info[:approvals_required],
          name: rule_name(policy[:name], rule_index),
          protected_branch_ids: project.protected_branches.get_ids_by_name(rule[:branches]),
          scanners: rule[:scanners],
          rule_type: :report_approver,
          severity_levels: rule[:severity_levels],
          user_ids: project.users.get_ids_by_username(action_info[:approvers]),
          vulnerabilities_allowed: rule[:vulnerabilities_allowed],
          report_type: :scan_finding
        }
      end

      def rule_name(policy_name, rule_index)
        truncated = policy_name.truncate(MAX_LENGTH, omission: '')
        return truncated if rule_index == 0

        "#{truncated} #{rule_index + 1}"
      end
    end
  end
end
