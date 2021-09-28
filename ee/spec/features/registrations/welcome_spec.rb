# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Welcome screen', :js do
  let_it_be(:user) { create(:user) }

  let(:experiments) { {} }

  context 'when on GitLab.com' do
    let(:user_has_memberships) { false }
    let(:in_subscription_flow) { false }
    let(:in_trial_flow) { false }

    before do
      stub_experiments(experiments)
      allow(Gitlab).to receive(:com?).and_return(true)
      gitlab_sign_in(user)
      allow_any_instance_of(EE::WelcomeHelper).to receive(:user_has_memberships?).and_return(user_has_memberships)
      allow_any_instance_of(EE::WelcomeHelper).to receive(:in_subscription_flow?).and_return(in_subscription_flow)
      allow_any_instance_of(EE::WelcomeHelper).to receive(:in_trial_flow?).and_return(in_trial_flow)

      visit users_sign_up_welcome_path
    end

    it 'shows the welcome page with a progress bar' do
      expect(page).to have_content('Welcome to GitLab')
      expect(page).to have_content('Your profile Your GitLab group Your first project')
      expect(page).to have_content('Continue')
    end

    context 'when in the subscription flow' do
      let(:in_subscription_flow) { true }

      it 'shows the progress bar with the correct steps' do
        expect(page).to have_content('Your profile Checkout Your GitLab group')
      end
    end

    context 'when user has memberships' do
      let(:user_has_memberships) { true }

      it 'does not show the progress bar' do
        expect(page).not_to have_content('Your profile')
      end
    end

    context 'when in the trial flow' do
      let(:in_trial_flow) { true }

      it 'does not show the progress bar' do
        expect(page).not_to have_content('Your profile')
      end
    end

    context 'with the jobs_to_be_done experiment' do
      let(:experiments) { { jobs_to_be_done: :candidate } }

      it 'allows specifying other for the jobs_to_be_done experiment', :experiment do
        expect(page).not_to have_content('Why are you signing up? (Optional)')

        select 'A different reason', from: 'user_registration_objective'

        expect(page).to have_content('Why are you signing up? (Optional)')

        fill_in 'jobs_to_be_done_other', with: 'My reason'
      end
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

  context 'when not on GitLab.com' do
    before do
      allow(Gitlab).to receive(:com?).and_return(false)
      gitlab_sign_in(user)

      visit users_sign_up_welcome_path
    end

    it 'does not show the progress bar' do
      expect(page).not_to have_content('Your profile')
      expect(page).to have_content('Get started!')
    end
  end
end
