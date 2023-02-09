# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/billings/_billing_plan_actions.html.haml', :saas do
  include SubscriptionPortalHelpers

  let(:plan) { Hashie::Mash.new(billing_plans_data.find { |plan_data| plan_data[:code] == 'free' }) }

  before do
    allow(view).to receive(:show_contact_sales_button?).and_return(true)
    allow(view).to receive(:plan).and_return(plan)
    allow(view).to receive(:purchase_link).and_return(plan.purchase_link)
    allow(view).to receive(:hand_raise_props).and_return({})
    allow(view).to receive(:plan_offer_type)
    allow(view).to receive(:show_upgrade_button)
    allow(view).to receive(:namespace)
    allow(view).to receive(:read_only)
  end

  it 'contains the hand raise lead selector and tracking' do
    css = ".js-hand-raise-lead-button"
    css += "[data-track-action='click_link']"
    css += "[data-track-label='hand_raise_lead_form']"
    css += "[data-track-property='#{plan.code}']"

    render

    expect(rendered).to have_css(css)
  end
end
