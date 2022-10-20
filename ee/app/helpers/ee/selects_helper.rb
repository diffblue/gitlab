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

    override :users_select_data_attributes
    def users_select_data_attributes(opts)
      super.merge(saml_provider_id: opts[:saml_provider_id] || nil)
    end

    override :users_select_tag
    def users_select_tag(id, opts = {})
      root_group = @group&.root_ancestor || @project&.group&.root_ancestor
      opts[:saml_provider_id] = root_group&.enforced_sso? && root_group.saml_provider&.id
      super(id, opts)
    end
  end
end
