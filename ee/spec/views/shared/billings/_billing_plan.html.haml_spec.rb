# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/billings/_billing_plan.html.haml', :saas do
  include SubscriptionPortalHelpers

  let(:plan) { Hashie::Mash.new(billing_plans_data.find { |plan_data| plan_data[:code] == 'free' }) }

  before do
    allow(view).to receive(:plan).and_return(plan)
    allow(view).to receive(:plan_offer_type)
    allow(view).to receive(:is_current)
    allow(view).to receive(:namespace)
  end

  it 'contains the feature link and tracking' do
    css = "[data-track-action='click_link']"
    css += "[data-track-label='plan_features']"
    css += "[data-track-property='#{plan.code}']"
    css += "[data-track-experiment='promote_premium_billing_page']"

    render

    expect(rendered).to have_link "See all #{plan.name} features", href: EE::SUBSCRIPTIONS_COMPARISON_URL
    expect(rendered).to have_css(css)
  end
end
