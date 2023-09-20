# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Welcome screen on SaaS', :js, :saas, feature_category: :onboarding do
  context 'with email opt in' do
    let(:user) { create(:user, role: nil) }

    before do
      gitlab_sign_in(user)

      visit users_sign_up_welcome_path
    end

    it 'does not show the email opt in checkbox when setting up for a company' do
      expect(page).to have_content('We won\'t share this information with anyone')
      expect(page).not_to have_selector('input[name="user[email_opted_in]', visible: :visible)

      choose 'user_setup_for_company_true'

      expect(page).not_to have_selector('input[name="opt_in_to_email]', visible: :visible)
    end

    it 'shows the email opt in checkbox when setting up for just me' do
      expect(page).to have_content('We won\'t share this information with anyone')
      expect(page).not_to have_selector('input[name="opt_in_to_email', visible: :visible)

      choose 'user_setup_for_company_false'

      expect(page).to have_selector('input[name="opt_in_to_email', visible: :visible)
    end
  end
end
