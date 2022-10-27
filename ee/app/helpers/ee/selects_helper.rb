# frozen_string_literal: true

module EE
  module SelectsHelper
    extend ::Gitlab::Utils::Override

    def ldap_server_select_options
      options_from_collection_for_select(
        ::Gitlab::Auth::Ldap::Config.available_servers,
        'provider_name',
        'label'
      )
    end

    def admin_email_select_tag(id, opts = {})
      css_class = ["ajax-admin-email-select gl-display-none"]
      css_class << "multiselect" if opts[:multiple]
      css_class << opts[:class] if opts[:class]
      value = opts[:selected] || ''

      text_field_tag(
        id,
        value,
        class: css_class.join(' '),
        required: true,
        title: s_('AdminEmail|Recipient group or project is required.')
      )
    end
  end
end
