# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin Dashboard', feature_category: :shared do
  before do
    admin = create(:admin)
    sign_in(admin)
    gitlab_enable_admin_mode_sign_in(admin)
  end

  describe 'Users statistic' do
    let_it_be(:users_statistics) { create(:users_statistics) }

    describe 'license' do
      before do
        allow(License).to receive(:current).and_return(license)
      end

      context 'for tooltip' do
        before do
          visit admin_dashboard_stats_path
        end

        context 'when license is empty' do
          let(:license) { nil }

          it { expect(page).not_to have_css('span.has-tooltip') }
        end

        context 'when license is on a plan Ultimate' do
          let(:license) { create(:license, plan: License::ULTIMATE_PLAN) }

          it { expect(page).to have_css('span.has-tooltip') }
        end

        context 'when license is on a plan other than Ultimate' do
          let(:license) { create(:license, plan: License::PREMIUM_PLAN) }

          it { expect(page).not_to have_css('span.has-tooltip') }
        end
      end

      context 'when user count over license maximum' do
        let_it_be(:license_seats_limit) { 5 }

        let(:license) { create(:license, restrictions: { active_user_count: license_seats_limit }) }

        before do
          create(:historical_data, date: license.created_at, active_user_count: license_seats_limit + 1)

          visit admin_root_path
        end

        it { expect(page).to have_content("Your instance has exceeded your subscription\'s licensed user count.") }
      end
    end

    it 'shows correct amounts of users', :aggregate_failures do
      visit admin_dashboard_stats_path

      expect(page).to have_content("Users without a Group and Project 23")
      expect(page).to have_content("Users with highest role Guest 5")
      expect(page).to have_content("Users with highest role Reporter 9")
      expect(page).to have_content("Users with highest role Developer 21")
      expect(page).to have_content("Users with highest role Maintainer 6")
      expect(page).to have_content("Users with highest role Owner 5")
      expect(page).to have_content("Bots 2")
      expect(page).to have_content("Billable users 69")
      expect(page).to have_content("Active users (total billable + total non-billable) 71")
      expect(page).to have_content("Blocked users 7")
      expect(page).to have_content("Total users (active users + blocked users) 78")
    end
  end

  describe 'qrtly reconciliation alert', :js do
    context 'on self-managed' do
      before do
        stub_ee_application_setting(should_check_namespace_plan: false)
      end

      context 'when qrtly reconciliation is available' do
        let_it_be(:reconciliation) { create(:upcoming_reconciliation, :self_managed) }

        before do
          visit(admin_root_path)
        end

        it_behaves_like 'a visible dismissible qrtly reconciliation alert'
      end

      context 'when qrtly reconciliation is not available' do
        before do
          visit(admin_root_path)
        end

        it_behaves_like 'a hidden qrtly reconciliation alert'
      end
    end
  end

  describe 'Version check', :js do
    it 'shows badge on EE' do
      visit admin_root_path

      page.within('.admin-dashboard') do
        expect(find('.badge')).to have_content('Up to date')
      end
    end
  end

  include_examples 'manual quarterly co-term banner', path_to_visit: :admin_subscription_path
end
