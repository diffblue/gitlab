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
        users_limit_dataset: ::Gitlab::Json.dump(
          {
            new_trial_registration_path: new_trial_path,
            members_path: group_usage_quotas_path(source.root_ancestor),
            purchase_path: group_billings_path(source.root_ancestor),
            reached_limit: free_user_cap.reached_limit?,
            close_to_dashboard_limit: free_user_cap.close_to_dashboard_limit?,
            remaining_seats: free_user_cap.remaining_seats,
            free_users_limit: ::Namespaces::FreeUserCap.dashboard_limit
          }
        )
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
