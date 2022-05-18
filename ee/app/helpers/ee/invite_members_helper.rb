# frozen_string_literal: true

module EE
  module InviteMembersHelper
    extend ::Gitlab::Utils::Override

    override :common_invite_modal_dataset
    def common_invite_modal_dataset(source)
      dataset = super

      if ::Namespaces::FreeUserCap::Standard.new(source.root_ancestor).enforce_cap?
        user_namespace = source.root_ancestor.user_namespace?

        members_path = if user_namespace
                         namespace_project_project_members_path(source.root_ancestor, source)
                       else
                         group_usage_quotas_path(source.root_ancestor)
                       end

        dataset.merge(
          users_limit_dataset: {
            user_namespace: user_namespace.to_s,
            new_trial_registration_path: new_trial_path,
            members_path: members_path,
            purchase_path: group_billings_path(source.root_ancestor),
            free_users_limit: ::Namespaces::FreeUserCap::FREE_USER_LIMIT,
            members_count: source.root_ancestor.free_plan_members_count
          }.to_json
        )
      else
        dataset
      end
    end

    override :users_filter_data
    def users_filter_data(group)
      root_group = group&.root_ancestor

      return {} unless root_group&.enforced_sso? && root_group.saml_provider&.id

      { users_filter: 'saml_provider_id', filter_id: root_group.saml_provider.id }
    end
  end
end
