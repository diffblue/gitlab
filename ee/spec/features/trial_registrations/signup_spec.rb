# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Trial Sign Up' do
  let(:user_attrs) { attributes_for(:user, first_name: 'GitLab', last_name: 'GitLab') }

  before do
    stub_application_setting(require_admin_approval_after_user_signup: false)
  end

  describe 'on GitLab.com' do
    before do
      allow(Gitlab).to receive(:com?).and_return(true).at_least(:once)
    end

    context 'with invalid email', :js do
      let(:email_error_message) { 'Please provide a valid email address.' }

      context 'with trialEmailValidation flag enabled' do
        it 'shows an error message until a correct email is entered' do
          visit new_trial_registration_path

          fill_in 'new_user_email', with: 'foo@'
          expect(page).to have_content(email_error_message)

          fill_in 'new_user_email', with: 'foo@bar'
          expect(page).to have_content(email_error_message)

          fill_in 'new_user_email', with: 'foo@gitlab.com'
          expect(page).not_to have_content(email_error_message)
        end
      end

      context 'when trialEmailValidation flag disabled' do
        before do
          stub_feature_flags trial_email_validation: false
        end

        it 'does not show an error message' do
          visit new_trial_registration_path

          fill_in 'new_user_email', with: 'foo@'

          expect(page).not_to have_content(email_error_message)
        end
      end
    end

    context 'with the unavailable username' do
      let(:existing_user) { create(:user) }

      it 'shows the error about existing username' do
        visit new_trial_registration_path
        click_on 'Continue'

        fill_in 'new_user_username', with: existing_user[:username]

        expect(page).to have_content('Username is already taken.')
      end
    end

    context 'with the available username' do
      it 'registers the user and proceeds to the next step' do
        stub_feature_flags(about_your_company_registration_flow: false)

        visit new_trial_registration_path
        click_on 'Continue'

        fill_in 'new_user_first_name', with: user_attrs[:first_name]
        fill_in 'new_user_last_name',  with: user_attrs[:last_name]
        fill_in 'new_user_username',   with: user_attrs[:username]
        fill_in 'new_user_email',      with: user_attrs[:email]
        fill_in 'new_user_password',   with: user_attrs[:password]

        click_button 'Continue'

        wait_for_requests

        select 'Software Developer', from: 'user_role'
        choose 'user_setup_for_company_true'
        click_button 'Continue'

        expect(page).to have_current_path(new_trial_path, ignore_query: true)
        expect(page).to have_content('Start your Free Ultimate Trial')
      end
    end
  end
end
