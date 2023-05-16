# frozen_string_literal: true

module Groups
  module DomainVerificationHelper
    def can_add_group_domain?(group)
      Feature.enabled?(:domain_verification_operation, group) &&
        (Gitlab.config.pages.external_http || Gitlab.config.pages.external_https)
    end

    def can_verify_group_domain?(domain)
      domain.persisted? && Gitlab::CurrentSettings.pages_domain_verification_enabled?
    end

    def can_add_group_domain_custom_certificate?
      Gitlab.config.pages.external_https
    end

    def group_domain_auto_ssl_available?
      ::Gitlab::LetsEncrypt.enabled?
    end
  end
end
