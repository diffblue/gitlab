# frozen_string_literal: true

module EE
  module ProfilesHelper
    extend ::Gitlab::Utils::Override

    override :ssh_key_expiration_tooltip
    def ssh_key_expiration_tooltip(key)
      return super unless ::Key.expiration_enforced? && key.expired?

      key.only_expired_and_enforced? ? s_('Profiles|Expired key is not valid.') : s_('Profiles|Invalid key.')
    end

    override :ssh_key_expires_field_description
    def ssh_key_expires_field_description
      return super unless ::Key.expiration_enforced?

      if ssh_key_expiration_policy_enabled?
        s_('Profiles|Key will be deleted on this date. Maximum lifetime for SSH keys is %{max_ssh_key_lifetime} days') % { max_ssh_key_lifetime: ::Gitlab::CurrentSettings.max_ssh_key_lifetime }
      else
        s_('Profiles|Key will be deleted on this date.')
      end
    end

    def ssh_key_expiration_policy_licensed?
      License.feature_available?(:ssh_key_expiration_policy) && ::Feature.enabled?(:ff_limit_ssh_key_lifetime)
    end

    def ssh_key_max_expiry_date
      ::Gitlab::CurrentSettings.max_ssh_key_lifetime_from_now
    end

    def ssh_key_expiration_policy_enabled?
      ::Gitlab::CurrentSettings.max_ssh_key_lifetime && ssh_key_expiration_policy_licensed? && ::Feature.enabled?(:ff_limit_ssh_key_lifetime)
    end
  end
end
