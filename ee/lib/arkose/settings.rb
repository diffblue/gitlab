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

    def self.enabled_for_signup?
      return false unless ::Feature.enabled?(:arkose_labs_signup_challenge)

      credentials_set?
    end

    def self.credentials_set?
      arkose_public_api_key.present? &&
        arkose_private_api_key.present? &&
        ::Gitlab::CurrentSettings.arkose_labs_namespace.present?
    end
    private_class_method :credentials_set?
  end
end
