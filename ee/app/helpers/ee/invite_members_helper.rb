# frozen_string_literal: true

module EE
  module InviteMembersHelper
    extend ::Gitlab::Utils::Override

    override :common_invite_modal_dataset
    def common_invite_modal_dataset(source)
      dataset = super

      if source.root_ancestor.apply_free_user_cap? && !source.root_ancestor.user_namespace?
        dataset.merge({
          new_trial_registration_path: new_trial_path,
          purchase_path: group_billings_path(source.root_ancestor),
          free_users_limit: ::Plan::FREE_USER_LIMIT,
          members_count: source.root_ancestor.free_plan_members_count
        })
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
