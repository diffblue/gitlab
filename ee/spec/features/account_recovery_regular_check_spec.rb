# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Account recovery regular check callout' do
  context 'when signed in' do
    let(:user) { create(:user, created_at: 4.months.ago ) }
    let(:message) { "We recommend you ensure two-factor authentication is enabled and the settings are up to date." }
    let(:action_button) { 'Manage two-factor authentication' }

    before do
      allow(Gitlab).to receive(:com?) { true }
      sign_in(user)
    end

    it 'shows callout if not dismissed' do
      visit root_dashboard_path

      expect(page).to have_content(message)
      expect(page).to have_link(action_button, href: profile_two_factor_auth_path)
    end

    it 'hides callout when user clicks action button', :js do
      visit root_dashboard_path

      expect(page).to have_content(message)

      click_link action_button
      wait_for_requests

      expect(page).not_to have_content(message)
    end

    it 'hides callout when user clicks close', :js do
      visit root_dashboard_path

      expect(page).to have_content(message)

      find('.js-recovery-settings-callout .js-close').click
      wait_for_requests

      expect(page).not_to have_content(message)
    end

    it 'shows callout on next session if user did not dismissed it' do
      visit root_dashboard_path

      expect(page).to have_content(message)

      gitlab_sign_out
      gitlab_sign_in(user)
      visit root_dashboard_path

      expect(page).to have_content(message)
    end
  end
end
