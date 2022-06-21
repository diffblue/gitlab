# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "projects/security/discover/show", type: :view do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }

  let(:pql_three_cta_test_variant) { :control }
  let(:showcase_free_security_features_variant) { :control }

  before do
    stub_experiments(
      pql_three_cta_test: pql_three_cta_test_variant,
      showcase_free_security_features: showcase_free_security_features_variant
    )
    allow(view).to receive(:current_user).and_return(user)
    assign(:project, project)
    render
  end

  it 'renders vue app root with correct link' do
    expect(rendered).to have_selector('#js-security-discover-app[data-link-main="/-/trial_registrations/new?glm_content=discover-project-security&glm_source=gitlab.com"]')
  end

  context 'candidate for pql_three_cta_test' do
    let(:pql_three_cta_test_variant) { :candidate }

    it 'renders vue app root with candidate url' do
      expect(rendered).to have_selector('#js-security-discover-app[data-link-main="/-/trial_registrations/new?glm_content=discover-project-security-pqltest&glm_source=gitlab.com"]')
    end
  end

  context 'candidate for showcase_free_security_features' do
    let(:showcase_free_security_features_variant) { :candidate }

    it 'renders showcase and not security discover element' do
      expect(rendered).not_to have_selector('#js-security-discover-app')
      expect(rendered).to have_selector('#js-security-showcase-app')
    end
  end
end
