# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Welcome screen', :js, :saas do
  let_it_be(:user) { create(:user, role: nil) }

  context 'when on GitLab.com' do
    before do
      gitlab_sign_in(user)
      allow_any_instance_of(EE::WelcomeHelper).to receive(:user_has_memberships?).and_return(false)
      allow_any_instance_of(EE::WelcomeHelper).to receive(:in_subscription_flow?).and_return(false)
      allow_any_instance_of(EE::WelcomeHelper).to receive(:in_trial_flow?).and_return(false)

      visit users_sign_up_welcome_path
    end

    context 'email opt in' do
      let(:user) { create(:user, email_opted_in: false) }

      it 'does not show the email opt in checkbox when setting up for a company' do
        expect(page).not_to have_selector('input[name="user[email_opted_in]', visible: true)

        page.select('Software Developer', from: 'user_role')
        choose 'user_setup_for_company_true'
        choose 'Create a new project'

        expect(page).not_to have_selector('input[name="user[email_opted_in]', visible: true)

        click_button 'Continue'

        expect(user.reload.email_opted_in).to eq(true)
      end

      it 'shows the email opt in checkbox when setting up for just me' do
        expect(page).not_to have_selector('input[name="user[email_opted_in]', visible: true)

        page.select('Software Developer', from: 'user_role')
        choose 'user_setup_for_company_false'
        choose 'Create a new project'

        expect(page).to have_selector('input[name="user[email_opted_in]', visible: true)

        click_button 'Continue'

        expect(user.reload.email_opted_in).to eq(false)
      end
    end
  end
end
