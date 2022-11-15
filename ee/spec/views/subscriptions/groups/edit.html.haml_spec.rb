# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'subscriptions/groups/edit' do
  let(:group) { Group.new }
  let(:user) { User.new }

  before do
    assign(:group, group)

    allow(view).to receive(:params).and_return(quantity: quantity)
    allow(view).to receive(:plan_title).and_return('Bronze')
    allow(view).to receive(:group_path).and_return('')
    allow(view).to receive(:subscriptions_groups_path).and_return('')
    allow(view).to receive(:current_user).and_return(user)
  end

  let(:quantity) { '1' }

  it 'tracks purchase banner', :snowplow do
    render

    expect_snowplow_event(
      category: 'subscriptions:groups',
      action: 'render',
      label: 'purchase_confirmation_alert_displayed',
      namespace: group,
      user: user
    )
  end

  context 'a single user' do
    it 'displays the correct notification for 1 user' do
      render

      expect(rendered).to have_text('You\'ve successfully purchased the Bronze plan subscription for 1 user and ' \
                                    'you\'ll receive a receipt by email. Your purchase may take a minute to sync, ' \
                                    'refresh the page if your subscription details haven\'t displayed yet.')
    end
  end

  context 'multiple users' do
    let(:quantity) { '2' }

    it 'displays the correct notification for 2 users' do
      render

      expect(rendered).to have_text('You\'ve successfully purchased the Bronze plan subscription for 2 users and ' \
                                    'you\'ll receive a receipt by email. Your purchase may take a minute to sync, ' \
                                    'refresh the page if your subscription details haven\'t displayed yet.')
    end
  end

  context 'with new_user in the params' do
    before do
      allow(view).to receive(:params).and_return(new_user: 'true')
    end

    it 'displays the progress bar' do
      render

      expect(rendered).to have_selector('#progress-bar')
    end
  end

  context 'without new_user in the params' do
    it 'does not display the progress bar' do
      render

      expect(rendered).not_to have_selector('#progress-bar')
    end
  end
end
