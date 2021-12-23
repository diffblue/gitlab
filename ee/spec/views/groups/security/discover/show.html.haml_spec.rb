# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "groups/security/discover/show", type: :view do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  let(:variant) { :control }

  before do
    stub_experiments(pql_three_cta_test: variant)
    allow(view).to receive(:current_user).and_return(user)
    assign(:group, group)
    render
  end

  it 'renders vue app root with correct link' do
    expect(rendered).to have_selector('#js-security-discover-app[data-link-main="/-/trial_registrations/new?glm_content=discover-group-security&glm_source=gitlab.com"]')
  end

  context 'candidate for pql_three_cta_test' do
    let(:variant) { :candidate }

    it 'renders vue app root with candidate url' do
      expect(rendered).to have_selector('#js-security-discover-app[data-link-main="/-/trial_registrations/new?glm_content=discover-group-security-pqltest&glm_source=gitlab.com"]')
    end
  end
end
