# frozen_string_literal: true

module Security
  module SecurityOrchestrationPolicies
    class FetchPolicyApproversService
      include BaseServiceUtility

      def initialize(policy:, container:, current_user:)
        @policy = policy
        @container = container
        @current_user = current_user
      end

      def execute
        action = required_approval(policy)

        return success({ users: [], groups: [], all_groups: [], roles: [] }) unless action

        group_approvers = group_approvers(action)

        success({
          users: user_approvers(action),
          groups: group_approvers[:visible],
          all_groups: group_approvers[:all],
          roles: role_approvers(action)
        })
      end

      private

      attr_reader :policy, :container, :current_user

      def required_approval(policy)
        policy&.fetch(:actions)&.find { |action| action&.fetch(:type) == Security::ScanResultPolicy::REQUIRE_APPROVAL }
      end

      def user_approvers(action)
        return [] unless action[:user_approvers] || action[:user_approvers_ids]

        user_names, user_ids = approvers_within_limit(action[:user_approvers], action[:user_approvers_ids])
        case container
        when Project
          container.team.users.by_ids_or_usernames(user_ids, user_names)
        when Group
          authorizable_users_in_group_hierarchy_by_ids_or_usernames(user_ids, user_names)
        else
          []
        end
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def authorizable_users_in_group_hierarchy_by_ids_or_usernames(user_ids, user_names)
        User
          .by_ids_or_usernames(user_ids, user_names)
          .where(
            container
              .authorizable_members_with_parents
              .merge(Member.where(Member.arel_table[:user_id].eq(User.arel_table[:id])), rewhere: true)
              .select(1)
              .arel
              .exists
          )
          .allow_cross_joins_across_databases(url: "https://gitlab.com/gitlab-org/gitlab/-/issues/417460")
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def group_approvers(action)
        return { visible: [], all: [] } unless action[:group_approvers] || action[:group_approvers_ids]

        group_paths, group_ids = approvers_within_limit(action[:group_approvers], action[:group_approvers_ids])

        service = Security::ApprovalGroupsFinder.new(group_ids: group_ids,
          group_paths: group_paths,
          user: current_user,
          container: container,
          search_globally: search_groups_globally?)

        visible = service.execute
        all = service.execute(include_inaccessible: true)

        { visible: visible, all: all }
      end

      def role_approvers(action)
        action[:role_approvers].to_a & Security::ScanResultPolicy::ALLOWED_ROLES
      end

      def search_groups_globally?
        Gitlab::CurrentSettings.security_policy_global_group_approvers_enabled?
      end

      def approvers_within_limit(names, ids)
        filtered_names = names&.first(Security::ScanResultPolicy::APPROVERS_LIMIT) || []
        filtered_ids = []

        if filtered_names.count < Security::ScanResultPolicy::APPROVERS_LIMIT
          filtered_ids = ids&.first(Security::ScanResultPolicy::APPROVERS_LIMIT - filtered_names.count)
        end

        [filtered_names, filtered_ids]
      end
    end
  end
end
