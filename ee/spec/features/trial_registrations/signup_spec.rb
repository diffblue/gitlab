# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Trial Sign Up', :saas, feature_category: :purchase do
  before do
    stub_application_setting(require_admin_approval_after_user_signup: false)
    stub_feature_flags(arkose_labs_trial_signup_challenge: false)
  end

  let_it_be(:new_user) { build_stubbed(:user) }

  describe 'on GitLab.com' do
    context 'with invalid email', :js do
      it_behaves_like 'user email validation' do
        let(:path) { new_user_registration_path }
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

    context 'when ArkoseLabs is enabled for trial signups', :js do
      before do
        stub_feature_flags(arkose_labs_trial_signup_challenge: true)
      end

      it_behaves_like 'creates a user with ArkoseLabs risk band' do
        let(:signup_path) { new_trial_registration_path }
        let(:user_email) { new_user.email }
        let(:fill_and_submit_signup_form) do
          fill_signup_form(new_user)

          click_button 'Continue'
        end
      end
    end

    context 'when reCAPTCHA is enabled', :js do
      before do
        stub_application_setting(recaptcha_enabled: true)
      end

      it 'creates the user' do
        visit new_trial_registration_path
        fill_signup_form(new_user)

        expect { click_button 'Continue' }.to change { User.count }
      end

      context 'when reCAPTCHA verification fails' do
        before do
          allow_next_instance_of(TrialRegistrationsController) do |instance|
            allow(instance).to receive(:verify_recaptcha).and_return(false)
          end
        end

        it 'does not create the user' do
          visit new_trial_registration_path
          fill_signup_form(new_user)

          expect { click_button 'Continue' }.not_to change { User.count }
          expect(page).to have_content(_('There was an error with the reCAPTCHA. Please solve the reCAPTCHA again.'))
        end
      end
    end

    def fill_signup_form(user)
      fill_in 'new_user_first_name', with: user.first_name
      fill_in 'new_user_last_name', with: user.last_name
      fill_in 'new_user_username', with: user.username
      fill_in 'new_user_email', with: user.email
      fill_in 'new_user_password', with: user.password
    end
  end
end
