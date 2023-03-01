# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Trial Sign Up', :saas, feature_category: :purchase do
  before do
    stub_application_setting(require_admin_approval_after_user_signup: false)
    stub_feature_flags(arkose_labs_signup_challenge: false)
  end

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

    context 'when arkose_labs_signup_challenge is enabled', :js do
      let(:new_user) { build(:user) }

      before do
        stub_feature_flags(arkose_labs_signup_challenge: true)
        stub_application_setting(
          arkose_labs_public_api_key: 'public_key',
          arkose_labs_private_api_key: 'private_key'
        )
      end

      shared_examples 'creates the user' do
        it 'creates the user' do
          fill_and_submit_signup_form(new_user)

          expect(User.find_by_username!(new_user[:username])).not_to be_nil
        end
      end

      it_behaves_like 'creates the user'

      context 'when reCAPTCHA is enabled' do
        before do
          stub_application_setting(recaptcha_enabled: true)
        end

        it_behaves_like 'creates the user'

        context 'when reCAPTCHA verification fails' do
          before do
            allow_next_instance_of(TrialRegistrationsController) do |instance|
              allow(instance).to receive(:verify_recaptcha).and_return(false)
            end
          end

          it 'does not create the user' do
            fill_and_submit_signup_form(new_user)

            expect(User.find_by_username(new_user[:username])).to be_nil
            expect(page).to have_content(_('There was an error with the reCAPTCHA. Please solve the reCAPTCHA again.'))
          end
        end
      end

      def fill_and_submit_signup_form(user)
        visit new_trial_registration_path

        fill_in 'new_user_first_name', with: user.first_name
        fill_in 'new_user_last_name', with: user.last_name
        fill_in 'new_user_username', with: user.username
        fill_in 'new_user_email', with: user.email
        fill_in 'new_user_password', with: user.password

        click_button 'Continue'
      end
    end
  end
end
