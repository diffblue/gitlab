# frozen_string_literal: true

module Groups
  module DomainVerificationHelper
    def can_add_group_domain?(group)
      Feature.enabled?(:domain_verification_operation, group)
    end

    def can_verify_group_domain?(domain)
      domain.persisted?
    end

    def group_domain_auto_ssl_available?
      ::Gitlab::LetsEncrypt.enabled?
    end
  end
end
