# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Welcome screen on SaaS', :js, :saas, feature_category: :onboarding do
  context 'with email opt in' do
    let(:user) { create(:user, role: nil, email_opted_in: false) }

    before do
      gitlab_sign_in(user)

      visit users_sign_up_welcome_path
    end

    it 'does not show the email opt in checkbox when setting up for a company' do
      expect(page).to have_content('We won\'t share this information with anyone')
      expect(page).not_to have_selector('input[name="user[email_opted_in]', visible: :visible)

      page.select('Software Developer', from: 'user_role')
      choose 'user_setup_for_company_true'
      choose 'Create a new project'

      expect(page).not_to have_selector('input[name="user[email_opted_in]', visible: :visible)

      click_button 'Continue'

      expect(user.reload.email_opted_in).to eq(true)
    end

    it 'shows the email opt in checkbox when setting up for just me' do
      expect(page).to have_content('We won\'t share this information with anyone')
      expect(page).not_to have_selector('input[name="user[email_opted_in]', visible: :visible)

      page.select('Software Developer', from: 'user_role')
      choose 'user_setup_for_company_false'
      choose 'Create a new project'

      expect(page).to have_selector('input[name="user[email_opted_in]', visible: :visible)

      click_button 'Continue'

      expect(user.reload.email_opted_in).to eq(false)
    end
  end
end
