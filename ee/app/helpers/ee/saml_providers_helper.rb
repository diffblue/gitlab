# frozen_string_literal: true

module EE
  module SamlProvidersHelper
    def saml_link_for_provider(text, provider, **args)
      saml_link(text, provider.group.full_path, **args)
    end

    def saml_link(text, group_path, redirect: nil, html_class: 'btn', id: nil, data: nil)
      redirect ||= group_path(group_path)
      url = omniauth_authorize_path(:user, :group_saml, group_path: group_path, redirect_to: redirect)

      link_to(text, url, method: :post, class: html_class, id: id, data: data)
    end
  end
end
