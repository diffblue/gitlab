# frozen_string_literal: true
#
require "spec_helper"

RSpec.describe EE::SamlProvidersHelper, feature_category: :system_access do
  let_it_be_with_reload(:current_user) { create_default(:user, name: "John Doe", username: "john") }
  let_it_be_with_reload(:group) { create_default(:group, :public, name: "circuitverse") }

  describe "#saml_sign_in" do
    it "returns a hash with a sign in button text property, merged with SAML properties" do
      button_text = "Sign me in"
      redirect = "my_redirect"
      group_path = group.path
      group_name = group.full_name
      allow(helper)
        .to receive(:omniauth_authorize_path)
        .with(:user, :group_saml, { group_path: "circuitverse", redirect_to: redirect })
        .and_return("/users/auth/group_saml?group_path=circuitverse&redirect_to=#{redirect}")

      saml_data = helper.group_saml_sign_in(
        group: group,
        group_name: group_name,
        group_path: group_path,
        redirect: redirect,
        sign_in_button_text: button_text
      )

      expect(saml_data).to eq(
        {
          group_name: "circuitverse",
          group_url: "/circuitverse",
          rememberable: "true",
          saml_url: "/users/auth/group_saml?group_path=circuitverse&redirect_to=#{redirect}",
          sign_in_button_text: button_text
        })
    end
  end
end
