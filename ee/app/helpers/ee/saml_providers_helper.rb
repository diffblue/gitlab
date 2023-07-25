# frozen_string_literal: true

module EE
  module SamlProvidersHelper
    def saml_link_for_provider(text, provider, **args)
      saml_button(text, provider.group.full_path, **args)
    end

    def saml_button(text, group_path, redirect: nil, variant: :default, block: false, **button_options)
      url = saml_url(group_path, redirect)
      render Pajamas::ButtonComponent.new(
        href: url,
        method: :post,
        variant: variant,
        block: block,
        button_options: button_options) do
        text
      end
    end

    def saml_link(text, group_path, redirect: nil, html_class: '', id: nil, data: nil)
      url = saml_url(group_path, redirect)
      link_to(text, url, method: :post, class: html_class, id: id, data: data)
    end

    def group_saml_sign_in(group:, group_name:, group_path:, redirect:, sign_in_button_text:)
      {
        group_name: group_name,
        group_url: group_path(group),
        rememberable: Devise.mappings[:user].rememberable?.to_s,
        saml_url: saml_url(group_path, redirect),
        sign_in_button_text: sign_in_button_text
      }
    end

    private

    def saml_url(group_path, redirect = nil)
      redirect ||= group_path(group_path)

      omniauth_authorize_path(:user, :group_saml, group_path: group_path, redirect_to: redirect)
    end
  end
end
