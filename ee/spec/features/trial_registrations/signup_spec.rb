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
      before do
        stub_feature_flags(arkose_labs_signup_challenge: true)
        stub_application_setting(
          arkose_labs_public_api_key: 'public_key',
          arkose_labs_private_api_key: 'private_key'
        )

        visit new_trial_registration_path
      end

      it 'creates the user' do
        new_user = build(:user)

        fill_in 'new_user_first_name', with: new_user.first_name
        fill_in 'new_user_last_name', with: new_user.last_name
        fill_in 'new_user_username', with: new_user.username
        fill_in 'new_user_email', with: new_user.email
        fill_in 'new_user_password', with: new_user.password

        click_button 'Continue'

        expect(User.find_by_username!(new_user[:username])).not_to be_nil
      end
    end
  end
end
