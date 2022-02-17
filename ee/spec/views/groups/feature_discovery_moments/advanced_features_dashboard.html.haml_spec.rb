# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'groups/feature_discovery_moments/advanced_features_dashboard.html.haml' do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  before do
    group.add_owner(user)
    allow(view).to receive(:current_user) { user }
    assign(:group, group)
    render
  end

  subject { rendered }

  it { is_expected.to have_content(s_('InProductMarketing|Discover Premium & Ultimate.')) }
  it { is_expected.to have_content(s_('InProductMarketing|Speed. Efficiency. Trust.')) }

  it 'renders the start a trial CTA', :aggregate_failures do
    expect(rendered).to have_link(s_('InProductMarketing|Start a free trial'),
      href: new_trial_path(glm_content: 'cross_stage_fdm', glm_source: 'gitlab.com')
    )
    expect(rendered).to have_css('[data-track-action="click_button"][data-track-label="start_trial"][data-track-experiment="cross_stage_fdm"]')
  end

  it 'renders the HandRaiseLeadButton Vue app glue', :aggregate_failures do
    expect(rendered).to have_css('.js-hand-raise-lead-button[data-glm-content="cross_stage_fdm"]')
    expect(rendered).to have_css('.js-hand-raise-lead-button[data-track-action="click_button"][data-track-label="hand_raise_PQL"][data-track-experiment="cross_stage_fdm"]')
  end
end
