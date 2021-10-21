# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Welcome screen', :js do
  let_it_be(:user) { create(:user) }

  context 'when on GitLab.com' do
    before do
      allow(Gitlab).to receive(:com?).and_return(true)
      gitlab_sign_in(user)
      allow_any_instance_of(EE::WelcomeHelper).to receive(:user_has_memberships?).and_return(false)
      allow_any_instance_of(EE::WelcomeHelper).to receive(:in_subscription_flow?).and_return(false)
      allow_any_instance_of(EE::WelcomeHelper).to receive(:in_trial_flow?).and_return(false)

      visit users_sign_up_welcome_path
    end

    it 'shows the welcome page' do
      expect(page).to have_content('Welcome to GitLab')
      expect(page).to have_content('Continue')
    end

    it 'allows specifying other for jobs_to_be_done' do
      expect(page).not_to have_content('Why are you signing up? (Optional)')

      select 'A different reason', from: 'user_registration_objective'

      expect(page).to have_content('Why are you signing up? (Optional)')

      fill_in 'jobs_to_be_done_other', with: 'My reason'
    end

    context 'email opt in' do
      it 'does not show the email opt in checkbox when setting up for a company' do
        expect(page).not_to have_selector('input[name="user[email_opted_in]', visible: true)

        choose 'user_setup_for_company_true'

        expect(page).not_to have_selector('input[name="user[email_opted_in]', visible: true)

        click_button 'Continue'

        expect(user.reload.email_opted_in).to eq(true)
      end

      it 'shows the email opt checkbox in when setting up for just me' do
        expect(page).not_to have_selector('input[name="user[email_opted_in]', visible: true)

        choose 'user_setup_for_company_false'

        expect(page).to have_selector('input[name="user[email_opted_in]', visible: true)

        click_button 'Continue'

        expect(user.reload.email_opted_in).to eq(false)
      end
    end
  end
end
