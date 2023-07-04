# frozen_string_literal: true

module Arkose
  class Settings
    def self.arkose_public_api_key
      ::Gitlab::CurrentSettings.arkose_labs_public_api_key || ENV['ARKOSE_LABS_PUBLIC_KEY']
    end

    def self.arkose_private_api_key
      ::Gitlab::CurrentSettings.arkose_labs_private_api_key || ENV['ARKOSE_LABS_PRIVATE_KEY']
    end

    def self.arkose_labs_domain
      "#{::Gitlab::CurrentSettings.arkose_labs_namespace}-api.arkoselabs.com"
    end

    def self.enabled?(user:, user_agent:)
      arkose_public_api_key.present? &&
        arkose_private_api_key.present? &&
        ::Gitlab::CurrentSettings.arkose_labs_namespace.present? &&
        !::Gitlab::Qa.request?(user_agent) &&
        !group_saml_user(user)
    end

    def self.group_saml_user(user)
      user.group_saml_identities.with_provider(::Users::BuildService::GROUP_SAML_PROVIDER).any?
    end
    private_class_method :group_saml_user
  end
end
