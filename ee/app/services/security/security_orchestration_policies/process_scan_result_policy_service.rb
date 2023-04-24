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
        action_info = policy[:actions]&.find { |action| action[:type] == Security::ScanResultPolicy::REQUIRE_APPROVAL }
        return if action_info.blank? || policy[:rules].blank?

        policy[:rules].first(Security::ScanResultPolicy::LIMIT).each_with_index do |rule, rule_index|
          next unless rule_type_allowed?(rule[:type])

          if create_scan_result_policy_read?(action_info, rule)
            scan_result_policy_read = create_scan_result_policy(rule, action_info)
          end

          create_software_license_policies(rule, rule_index, scan_result_policy_read) if license_finding?(rule)

          ::ApprovalRules::CreateService
            .new(project, author, rule_params(rule, rule_index, action_info, scan_result_policy_read))
            .execute
        end
      end

      def license_finding?(rule)
        rule[:type] == Security::ScanResultPolicy::LICENSE_FINDING
      end

      def create_scan_result_policy_read?(action_info, rule)
        scan_result_role_action_enabled || license_finding?(rule)
      end

      def create_software_license_policies(rule, _rule_index, scan_result_policy_read)
        rule[:license_types].each do |license_type|
          create_params = {
            name: license_type,
            approval_status: rule[:match_on_inclusion] ? 'denied' : 'allowed',
            scan_result_policy_read: scan_result_policy_read
          }

          ::SoftwareLicensePolicies::CreateService
            .new(project, author, create_params)
            .execute(is_scan_result_policy: true)
        end
      end

      def create_scan_result_policy(rule, action_info)
        policy_configuration.scan_result_policy_reads.create!(
          orchestration_policy_idx: policy_index,
          license_states: rule[:license_states],
          match_on_inclusion: rule[:match_on_inclusion] || false,
          role_approvers: role_access_levels(action_info[:role_approvers])
        )
      end

      def rule_params(rule, rule_index, action_info, scan_result_policy_read)
        protected_branch_ids = project.all_protected_branches.get_ids_by_name(rule[:branches])

        rule_params = {
          skip_authorization: true,
          approvals_required: action_info[:approvals_required],
          name: rule_name(policy[:name], rule_index),
          protected_branch_ids: protected_branch_ids,
          applies_to_all_protected_branches: rule[:branches].empty?,
          rule_type: :report_approver,
          user_ids: users_ids(action_info[:user_approvers_ids], action_info[:user_approvers]),
          report_type: report_type(rule[:type]),
          orchestration_policy_idx: policy_index,
          group_ids: groups_ids(action_info[:group_approvers_ids], action_info[:group_approvers]),
          security_orchestration_policy_configuration_id: policy_configuration.id,
          scan_result_policy_id: scan_result_policy_read&.id
        }

        rule_params[:severity_levels] = [] if rule[:type] == Security::ScanResultPolicy::LICENSE_FINDING

        if rule[:type] == Security::ScanResultPolicy::SCAN_FINDING
          rule_params.merge!({
            scanners: rule[:scanners],
            severity_levels: rule[:severity_levels],
            vulnerabilities_allowed: rule[:vulnerabilities_allowed],
            vulnerability_states: rule[:vulnerability_states]
          })
        end

        rule_params
      end

      def rule_type_allowed?(rule_type)
        [
          Security::ScanResultPolicy::SCAN_FINDING,
          Security::ScanResultPolicy::LICENSE_FINDING
        ].include?(rule_type)
      end

      def report_type(rule_type)
        rule_type == Security::ScanResultPolicy::LICENSE_FINDING ? :license_scanning : :scan_finding
      end

      def rule_name(policy_name, rule_index)
        return policy_name if rule_index == 0

        "#{policy_name} #{rule_index + 1}"
      end

      def scan_result_role_action_enabled
        @scan_result_role_action_enabled ||= Feature.enabled?(:scan_result_role_action, project)
      end

      def users_ids(user_ids, user_names)
        project.team.users.get_ids_by_ids_or_usernames(user_ids, user_names)
      end

      # rubocop: disable Cop/GroupPublicOrVisibleToUser
      def groups_ids(group_ids, group_paths)
        Security::ApprovalGroupsFinder.new(group_ids: group_ids,
          group_paths: group_paths,
          user: author,
          container: project.namespace,
          search_globally: search_groups_globally?).execute
      end
      # rubocop: enable Cop/GroupPublicOrVisibleToUser

      def role_access_levels(role_approvers)
        return [] unless role_approvers

        roles_map = Gitlab::Access.sym_options_with_owner
        role_approvers.filter_map { |role| roles_map[role.to_sym] }
      end

      def search_groups_globally?
        Gitlab::CurrentSettings.security_policy_global_group_approvers_enabled?
      end
    end
  end
end
