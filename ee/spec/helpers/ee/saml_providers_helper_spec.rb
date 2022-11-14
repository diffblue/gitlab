# frozen_string_literal: true
#
require 'spec_helper'

RSpec.describe EE::SamlProvidersHelper do
  let_it_be_with_reload(:current_user) { create(:user, name: 'John Doe', username: 'john') }
  let_it_be_with_reload(:group) { create(:group, :public, name: 'circuitverse') }

  describe '#saml_authorize' do
    it 'respond URL' do
      group_path = group.path
      group_name = group.full_name
      allow(helper)
        .to receive(:omniauth_authorize_path)
        .with(:user, :group_saml, { group_path: "circuitverse", redirect_to: "/circuitverse" })
        .and_return('/users/auth/saml')

      saml_data = helper.saml_authorize(
        group: group,
        group_name: group_name,
        group_path: group_path,
        user: current_user
      )

      expect(saml_data).to eq(
        {
          group_name: "circuitverse",
          group_url: "/circuitverse",
          rememberable: 'true',
          saml_url: "/users/auth/saml",
          user_full_name: "John Doe",
          user_url: "/john",
          username: "john"
        })
    end
  end
end
