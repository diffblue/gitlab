# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Subscription expired notification', :js, feature_category: :consumables_cost_management do
  let(:admin) { create(:admin) }
  let(:subscribable) { double(:license) }
  let(:expected_content) { 'Your subscription expired' }

  before do
    stub_application_setting(signup_enabled: false)
    stub_feature_flags(namespace_storage_limit_show_preenforcement_banner: false)

    sign_in(admin)
    gitlab_enable_admin_mode_sign_in(admin)
  end

  context 'for group namespace' do
    let(:message) { double(:message) }
    let(:group) { create(:group) }
    let(:plan_name) { ::Plan::PREMIUM }
    let(:auto_renew) { false }
    let!(:license) { create_current_license(cloud_licensing_enabled: false, plan: License::ULTIMATE_PLAN, expires_at: Date.current - 1.week) }

    before do
      allow(subscribable).to receive(:plan).and_return(plan_name)
      allow(subscribable).to receive(:expires_at).and_return(Date.current - 1.week)
      allow(subscribable).to receive(:auto_renew).and_return(auto_renew)

      visit group_path(group)
    end

    it 'displays and dismisses alert' do
      expect(page).to have_content(expected_content)

      within '[data-testid="subscribable_banner"]' do
        click_button('Dismiss')
      end

      visit group_path(group)

      expect(page).not_to have_content(expected_content)
    end
  end
end
