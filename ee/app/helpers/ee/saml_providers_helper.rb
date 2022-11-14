# frozen_string_literal: true

module EE
  module SamlProvidersHelper
    def saml_link_for_provider(text, provider, **args)
      saml_link(text, provider.group.full_path, **args)
    end

    def saml_link(text, group_path, redirect: nil, html_class: 'btn', id: nil, data: nil)
      url = saml_url(group_path, redirect)

      link_to(text, url, method: :post, class: html_class, id: id, data: data)
    end

    def saml_authorize(group:, group_name:, group_path:, user:)
      {
        group_name: group_name,
        group_url: group_path(group),
        rememberable: Devise.mappings[:user].rememberable?.to_s,
        saml_url: saml_url(group_path),
        username: user.username,
        user_full_name: user.name,
        user_url: user_path(user)
      }
    end

    private

    def saml_url(group_path, redirect = nil)
      redirect ||= group_path(group_path)

      omniauth_authorize_path(:user, :group_saml, group_path: group_path, redirect_to: redirect)
    end
  end
end
