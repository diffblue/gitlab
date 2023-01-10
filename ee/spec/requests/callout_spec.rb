# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'callout alerts', feature_category: :navigation do
  include Capybara::RSpecMatchers

  describe 'new_user_signups_cap_reached', :do_not_mock_admin_mode_setting do
    let_it_be(:user) { create(:admin) }

    let(:billable_users) { [double(:billable_user)] }
    let(:help_page_href) { help_page_path('user/admin_area/settings/sign_up_restrictions.md') }
    let(:expected_content) { 'Your instance has reached its user cap' }

    shared_examples_for 'a visible alert' do
      it 'shows the alert' do
        get root_dashboard_path

        expect(response.body).to include(expected_content)
        expect(response.body).to have_link('usage caps', href: help_page_href)
      end
    end

    shared_examples_for 'a hidden alert' do
      it 'does not show the alert' do
        get root_dashboard_path

        expect(response.body).not_to include(expected_content)
      end
    end

    before do
      stub_application_setting(new_user_signups_cap: 1)
      allow(User).to receive(:billable).and_return(billable_users)

      login_as(user)
    end

    context 'when cap reached' do
      it_behaves_like 'a visible alert'
    end

    context 'when cap not reached' do
      let(:billable_users) { [] }

      it_behaves_like 'a hidden alert'
    end

    context 'when user is not admin' do
      let_it_be(:user) { create(:user) }

      it_behaves_like 'a hidden alert'
    end
  end
end
