# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/billings/_billing_plans.html.haml', :saas do
  include SubscriptionPortalHelpers

  before do
    allow(view).to receive(:show_plans?).and_return(true)
    allow(view).to receive(:billing_available_plans).and_return({})
    allow(view).to receive(:plans_data)
    allow(view).to receive(:namespace).and_return(build(:namespace))
    allow(view).to receive(:current_plan)
  end

  it 'contains the feature link and tracking' do
    css = "[data-testid='billing-plans']"
    css += "[data-track-action='render']"
    css += "[data-track-label='billing']"

    render

    expect(rendered).to have_css(css)
  end
end
