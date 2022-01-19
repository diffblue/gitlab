# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Groups::SamlProvidersController, '(JavaScript fixtures)', type: :controller do
  include JavaScriptFixturesHelpers

  let(:group) { create(:group, :private) }
  let(:user) { create(:user) }

  render_views

  before do
    sign_in(user)
    group.add_owner(user)
    allow(Devise).to receive(:omniauth_providers).and_return(%i(group_saml))
    stub_licensed_features(group_saml: true)
  end

  it 'groups/saml_providers/show.html' do
    create(:saml_provider, group: group, enforced_sso: true)

    get :show, params: { group_id: group }

    expect(response).to be_successful
    expect(response).to render_template 'groups/saml_providers/show'
  end
end
