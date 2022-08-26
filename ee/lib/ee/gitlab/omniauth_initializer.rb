# frozen_string_literal: true

module EE
  module Gitlab
    module OmniauthInitializer
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override

      class_methods do
        extend ::Gitlab::Utils::Override

        override :full_host
        def full_host
          proc { |env| ::Gitlab::Geo.proxied_site(env)&.omniauth_host_url || Settings.gitlab['base_url'] }
        end
      end

      override :build_omniauth_customized_providers
      def build_omniauth_customized_providers
        super.concat(%i[kerberos group_saml])
      end

      override :setup_provider
      def setup_provider(provider)
        super

        if provider == :group_saml
          OmniAuth.config.on_failure =
            ::Gitlab::Auth::GroupSaml::FailureHandler.new(
              OmniAuth.config.on_failure)
        end
      end
    end
  end
end
