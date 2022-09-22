# frozen_string_literal: true

module EE
  module InviteMembersHelper
    extend ::Gitlab::Utils::Override

    override :common_invite_modal_dataset
    def common_invite_modal_dataset(source)
      dataset = super

      free_user_cap = ::Namespaces::FreeUserCap::Standard.new(source.root_ancestor)

      return dataset unless free_user_cap.enforce_cap?

      dataset.merge(
        users_limit_dataset: {
          new_trial_registration_path: new_trial_path,
          members_path: group_usage_quotas_path(source.root_ancestor),
          purchase_path: group_billings_path(source.root_ancestor),
          free_users_limit: ::Namespaces::FreeUserCap.dashboard_limit,
          members_count: free_user_cap.users_count
        }.to_json
      )
    end

    override :users_filter_data
    def users_filter_data(group)
      root_group = group&.root_ancestor

      return {} unless root_group&.enforced_sso? && root_group.saml_provider&.id

      { users_filter: 'saml_provider_id', filter_id: root_group.saml_provider.id }
    end
  end
end
