# frozen_string_literal: true

module EE
  module ProfilesHelper
    extend ::Gitlab::Utils::Override

    override :ssh_key_expires_field_description
    def ssh_key_expires_field_description
      return super unless ssh_key_expiration_policy_enabled?

      s_('Profiles|Key becomes invalid on this date. Maximum lifetime for SSH keys is %{max_ssh_key_lifetime} days') % { max_ssh_key_lifetime: ::Gitlab::CurrentSettings.max_ssh_key_lifetime }
    end

    def ssh_key_expiration_policy_licensed?
      License.feature_available?(:ssh_key_expiration_policy)
    end

    override :ssh_key_expiration_policy_enabled?
    def ssh_key_expiration_policy_enabled?
      ::Gitlab::CurrentSettings.max_ssh_key_lifetime && ssh_key_expiration_policy_licensed?
    end
  end
end
