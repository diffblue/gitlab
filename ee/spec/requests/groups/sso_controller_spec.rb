# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::SsoController, feature_category: :system_access do
  let_it_be(:group) { create(:group) }
  let_it_be(:saml_provider) { create(:saml_provider, group: group) }

  before do
    stub_licensed_features(group_saml: true)
    allow(Devise).to receive(:omniauth_providers).and_return(['group_saml'])
  end

  it_behaves_like 'Base action controller' do
    subject(:request) { get sso_group_saml_providers_path(group, token: group.saml_discovery_token) }
  end
end
