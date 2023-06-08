# frozen_string_literal: true

module Security
  module SecurityOrchestrationPolicies
    class ValidatePolicyService < ::BaseContainerService
      include ::Gitlab::Utils::StrongMemoize

      ValidationError = Struct.new(:field, :level, :message, :title)

      def execute
        return error_with_title(s_('SecurityOrchestration|Empty policy name')) if blank_name?

        return success if policy_disabled?

        return error_with_title(s_('SecurityOrchestration|Invalid policy type')) if invalid_policy_type?
        return error_with_title(s_('SecurityOrchestration|Policy cannot be enabled without branch information')) if blank_branch_for_rule?
        return error_with_title(s_('SecurityOrchestration|Policy cannot be enabled for non-existing branches (%{branches})') % { branches: missing_branch_names.join(', ') }) if missing_branch_for_rule?

        return error_with_title(s_('SecurityOrchestration|Required approvals exceed eligible approvers'), title: s_('SecurityOrchestration|Logic error'), field: "approvers_ids") if required_approvals_exceed_eligible_approvers?

        success
      end

      private

      def error_with_title(message, title: nil, field: nil, level: :error)
        pass_back = {
          details: [message],
          validation_errors: [ValidationError.new(field, level, message, title).to_h]
        }

        error(s_('SecurityOrchestration|Invalid policy'), :bad_request, pass_back: pass_back)
      end

      def policy_disabled?
        !policy&.[](:enabled)
      end

      def invalid_policy_type?
        return true if policy[:type].blank?

        !Security::OrchestrationPolicyConfiguration::AVAILABLE_POLICY_TYPES.include?(policy_type)
      end

      def blank_name?
        policy[:name].blank?
      end

      def blank_branch_for_rule?
        return false if scan_result_policy?

        policy[:rules].any? do |rule|
          rule.values_at(:agents, :branches, :branch_type).all?(&:blank?)
        end
      end

      def missing_branch_for_rule?
        return false if container.blank?
        return false unless project_container?

        missing_branch_names.present?
      end

      def required_approvals_exceed_eligible_approvers?
        approvals_required? && approvals_required_exceed_approvers?
      end

      def approvals_required?
        return false unless validate_approvals_required?
        return false unless scan_result_policy?
        return false unless action = approval_requiring_action

        # For group-level policies the number of role_approvers is project-dependent
        return false if group_container? && action.key?(:role_approvers)

        action.key?(:approvals_required)
      end

      def approvals_required_exceed_approvers?
        approvals_required = approval_requiring_action[:approvals_required]

        result = ::Security::SecurityOrchestrationPolicies::FetchPolicyApproversService.new(
          policy: policy,
          container: container,
          current_user: current_user
        ).execute

        eligible_user_ids = Set.new
        users, groups, roles = result.values_at(:users, :groups, :roles)

        eligible_user_ids.merge(users.pluck(:id)) # rubocop:disable CodeReuse/ActiveRecord
        return false if eligible_user_ids.size >= approvals_required

        eligible_user_ids.merge(user_ids_by_groups(groups))
        return false if eligible_user_ids.size >= approvals_required

        eligible_user_ids.merge(user_ids_by_roles(roles))
        eligible_user_ids.size < approvals_required
      end

      def user_ids_by_groups(groups)
        return [] if groups.empty?

        GroupMember.eligible_approvers_by_groups(groups).pluck_user_ids
      end

      def user_ids_by_roles(roles)
        return [] if roles.empty? || group_container?

        roles_map = Gitlab::Access.sym_options_with_owner
        access_levels = roles.filter_map { |role| roles_map[role.to_sym] }

        ProjectAuthorization.eligible_approvers_by_project_id_and_access_levels(project.id, access_levels).pluck_user_ids
      end

      def missing_branch_names
        strong_memoize(:missing_branch_names) do
          policy[:rules]
            .select { |rule| rule[:agents].blank? }
            .flat_map { |rule| rule[:branches] }
            .compact
            .uniq
            .select { |pattern| RefMatcher.new(pattern).matching(branches_for_project).blank? }
        end
      end

      def policy
        @policy ||= params[:policy]
      end

      def validate_approvals_required?
        params[:validate_approvals_required]
      end

      def branches_for_project
        strong_memoize(:branches_for_project) do
          container.repository.branch_names
        end
      end

      def policy_type
        policy[:type].to_sym
      end

      def scan_result_policy?
        policy_type == :scan_result_policy
      end

      def approval_requiring_action
        policy[:actions]&.find { |action| action[:type] == Security::ScanResultPolicy::REQUIRE_APPROVAL }
      end
      strong_memoize_attr :approval_requiring_action
    end
  end
end
