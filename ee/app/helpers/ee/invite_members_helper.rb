# frozen_string_literal: true

module EE
  module InviteMembersHelper
    extend ::Gitlab::Utils::Override

    override :users_filter_data
    def users_filter_data(group)
      root_group = group&.root_ancestor

      return {} unless root_group&.enforced_sso? && root_group.saml_provider&.id

      { users_filter: 'saml_provider_id', filter_id: root_group.saml_provider.id }
    end
  end
end
