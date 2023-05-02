# frozen_string_literal: true

module EE
  module AuthHelper
    extend ::Gitlab::Utils::Override

    PROVIDERS_WITH_ICONS = %w(
      kerberos
    ).freeze
    GROUP_LEVEL_PROVIDERS = %i(group_saml).freeze

    override :display_providers_on_profile?
    def display_providers_on_profile?
      super || group_saml_enabled?
    end

    override :button_based_providers
    def button_based_providers
      super - GROUP_LEVEL_PROVIDERS
    end

    override :providers_for_base_controller
    def providers_for_base_controller
      super - GROUP_LEVEL_PROVIDERS
    end

    override :provider_has_builtin_icon?
    def provider_has_builtin_icon?(name)
      super || PROVIDERS_WITH_ICONS.include?(name.to_s)
    end

    override :form_based_provider_priority
    def form_based_provider_priority
      super << 'smartcard'
    end

    override :form_based_providers
    def form_based_providers
      providers = super

      providers << :smartcard if smartcard_enabled?

      providers
    end

    def password_rule_list
      if ::License.feature_available?(:password_complexity)
        rules = []
        rules << :number if ::Gitlab::CurrentSettings.password_number_required?
        rules << :lowercase if ::Gitlab::CurrentSettings.password_lowercase_required?
        rules << :uppercase if ::Gitlab::CurrentSettings.password_uppercase_required?
        rules << :symbol if ::Gitlab::CurrentSettings.password_symbol_required?

        rules
      end
    end

    def kerberos_enabled?
      auth_providers.include?(:kerberos)
    end

    def smartcard_enabled?
      ::Gitlab::Auth::Smartcard.enabled?
    end

    def smartcard_enabled_for_ldap?(provider_name, required: false)
      return false unless smartcard_enabled?

      server = ::Gitlab::Auth::Ldap::Config.servers.find do |server|
        server['provider_name'] == provider_name
      end

      return false unless server

      truthy_values = ['required']
      truthy_values << 'optional' unless required

      truthy_values.include? server['smartcard_auth']
    end

    def smartcard_login_button_classes(provider_name)
      css_classes = %w[btn btn-success]
      css_classes << 'btn-inverted' unless smartcard_enabled_for_ldap?(provider_name, required: true)
      css_classes.join(' ')
    end

    def group_saml_enabled?
      auth_providers.include?(:group_saml)
    end
  end
end
