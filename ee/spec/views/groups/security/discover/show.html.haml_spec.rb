# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "groups/security/discover/show", type: :view do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  let(:showcase_free_security_features_variant) { :control }

  before do
    stub_experiments(showcase_free_security_features: showcase_free_security_features_variant)
    allow(view).to receive(:current_user).and_return(user)
    assign(:group, group)
    render
  end

  it 'renders vue app root with correct link' do
    expect(rendered).to have_selector('#js-security-discover-app[data-link-main="/-/trial_registrations/new?glm_content=discover-group-security&glm_source=gitlab.com"]')
  end

  context 'candidate for showcase_free_security_features' do
    let(:showcase_free_security_features_variant) { :candidate }

    it 'renders showcase and not security discover element' do
      expect(rendered).not_to have_selector('#js-security-discover-app')
      expect(rendered).to have_selector('#js-security-showcase-app')
    end
  end
end
