# frozen_string_literal: true

module Security
  module SecurityOrchestrationPolicies
    class ProcessScanResultPolicyService
      MAX_LENGTH = 25

      def initialize(policy_configuration:, policy:, policy_index:)
        @policy_configuration = policy_configuration
        @policy = policy
        @policy_index = policy_index
        @project = policy_configuration.project
        @author = policy_configuration.policy_last_updated_by
      end

      def execute
        return if ::Feature.disabled?(:scan_result_policy, project)

        create_new_approval_rules
      end

      private

      attr_reader :policy_configuration, :policy, :project, :author, :policy_index

      def create_new_approval_rules
        action_info = policy[:actions].find { |action| action[:type] == Security::ScanResultPolicy::REQUIRE_APPROVAL }
        return unless action_info

        policy[:rules].first(Security::ScanResultPolicy::LIMIT).each_with_index do |rule, rule_index|
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
          user_ids: users_ids(action_info[:user_approvers_ids], action_info[:user_approvers]),
          vulnerabilities_allowed: rule[:vulnerabilities_allowed],
          report_type: :scan_finding,
          orchestration_policy_idx: policy_index,
          vulnerability_states: rule[:vulnerability_states],
          group_ids: groups_ids(action_info[:group_approvers_ids], action_info[:group_approvers])
        }
      end

      def rule_name(policy_name, rule_index)
        truncated = policy_name.truncate(MAX_LENGTH)
        return truncated if rule_index == 0

        "#{truncated} #{rule_index + 1}"
      end

      def users_ids(user_ids, user_names)
        project.team.users.get_ids_by_ids_or_usernames(user_ids, user_names)
      end

      def groups_ids(group_ids, group_paths)
        Group.unscoped.public_to_user(author).get_ids_by_ids_or_paths(group_ids, group_paths)
      end
    end
  end
end
