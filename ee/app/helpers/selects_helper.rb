# frozen_string_literal: true

module SelectsHelper
  def ldap_server_select_options
    options_from_collection_for_select(
      ::Gitlab::Auth::Ldap::Config.available_servers,
      'provider_name',
      'label'
    )
  end
end
