# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/user_over_limit_free_plan_alert' do
  let_it_be(:source) { create(:group) }

  let(:partial) { 'shared/user_over_limit_free_plan_alert' }

  before do
    allow(view).to receive(:source).and_return(source)
    allow(view).to receive(:show_user_over_limit_free_plan_alert?).with(source).and_return(true)
  end

  it 'renders all the expected tracking items', :aggregate_failures do
    render partial

    expect(view.content_for(:user_over_limit_free_plan_alert))
      .to have_css('.js-user-over-limit-free-plan-alert[data-track-action="render"][data-track-label="user_limit_banner"]')
    expect(view.content_for(:user_over_limit_free_plan_alert))
      .to have_css('[data-testid="user-over-limit-free-plan-dismiss"][data-track-action="dismiss_banner"][data-track-label="user_limit_banner"]')
    expect(view.content_for(:user_over_limit_free_plan_alert))
      .to have_css('[data-testid="user-over-limit-free-plan-manage"][data-track-action="click_button"][data-track-label="manage_members"]')
    expect(view.content_for(:user_over_limit_free_plan_alert))
      .to have_css('[data-testid="user-over-limit-free-plan-explore"][data-track-action="click_button"][data-track-label="explore_paid_plans"]')
  end

  it 'renders all the correct links and buttons', :aggregate_failures do
    render partial

    expect(view.content_for(:user_over_limit_free_plan_alert))
      .to have_link('Manage members', href: group_usage_quotas_path(source))
    expect(view.content_for(:user_over_limit_free_plan_alert))
      .to have_link('Explore paid plans', href: group_billings_path(source))
    expect(view.content_for(:user_over_limit_free_plan_alert))
      .to have_link('status of Over limit', href: 'https://about.gitlab.com/blog/2022/03/24/efficient-free-tier')
    expect(view.content_for(:user_over_limit_free_plan_alert))
      .to have_css("[data-testid='user-over-limit-free-plan-alert'][data-dismiss-endpoint='#{group_callouts_path}'][data-feature-id='#{Users::GroupCalloutsHelper::PREVIEW_USER_OVER_LIMIT_FREE_PLAN_ALERT}'][data-group-id='#{source.id}']")
  end
end
