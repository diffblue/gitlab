# frozen_string_literal: true

module Security
  module SecurityOrchestrationPolicies
    class ProcessScanResultPolicyService
      def initialize(project:, policy_configuration:, policy:, policy_index:)
        @policy_configuration = policy_configuration
        @policy = policy
        @policy_index = policy_index
        @project = project
        @author = policy_configuration.policy_last_updated_by
      end

      def execute
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
        protected_branch_ids = if ::Feature.enabled?(:group_protected_branches)
                                 project.all_protected_branches.get_ids_by_name(rule[:branches])
                               else
                                 project.protected_branches.get_ids_by_name(rule[:branches])
                               end

        {
          skip_authorization: true,
          approvals_required: action_info[:approvals_required],
          name: rule_name(policy[:name], rule_index),
          protected_branch_ids: protected_branch_ids,
          applies_to_all_protected_branches: rule[:branches].empty?,
          scanners: rule[:scanners],
          rule_type: :report_approver,
          severity_levels: rule[:severity_levels],
          user_ids: users_ids(action_info[:user_approvers_ids], action_info[:user_approvers]),
          vulnerabilities_allowed: rule[:vulnerabilities_allowed],
          report_type: :scan_finding,
          orchestration_policy_idx: policy_index,
          vulnerability_states: rule[:vulnerability_states],
          group_ids: groups_ids(action_info[:group_approvers_ids], action_info[:group_approvers]),
          security_orchestration_policy_configuration_id: policy_configuration.id
        }
      end

      def rule_name(policy_name, rule_index)
        return policy_name if rule_index == 0

        "#{policy_name} #{rule_index + 1}"
      end

      def users_ids(user_ids, user_names)
        project.team.users.get_ids_by_ids_or_usernames(user_ids, user_names)
      end

      # rubocop: disable Cop/GroupPublicOrVisibleToUser
      def groups_ids(group_ids, group_paths)
        Group.public_or_visible_to_user(author).get_ids_by_ids_or_paths(group_ids, group_paths)
      end
      # rubocop: enable Cop/GroupPublicOrVisibleToUser
    end
  end
end
