# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Signup on EE', :js, feature_category: :user_profile do
  let(:new_user) { build_stubbed(:user) }

  before do
    stub_application_setting(require_admin_approval_after_user_signup: false)
    stub_feature_flags(arkose_labs_signup_challenge: false)
  end

  def fill_in_signup_form
    fill_in 'new_user_username', with: new_user.username
    fill_in 'new_user_email', with: new_user.email
    fill_in 'new_user_first_name', with: new_user.first_name
    fill_in 'new_user_last_name', with: new_user.last_name
    fill_in 'new_user_password', with: new_user.password

    wait_for_all_requests
  end

  context 'for SaaS', :saas do
    before do
      stub_ee_application_setting(should_check_namespace_plan: true)
      visit new_user_registration_path
    end

    it 'allows visiting of a page after initial registration' do
      fill_in_signup_form
      click_button 'Register'
      visit new_project_path

      expect(page).to have_current_path(users_sign_up_welcome_path)

      select 'Software Developer', from: 'user_role'
      choose 'user_setup_for_company_true'
      choose 'Join a project'
      click_button 'Continue'
      user = User.find_by_username(new_user[:username])

      expect(user.software_developer_role?).to be_truthy
      expect(user.setup_for_company).to be_truthy
    end
  end

  describe 'password complexity', :js do
    let(:path_to_visit) { new_user_registration_path }
    let(:password_input_selector) { :new_user_password }
    let(:submit_button_selector) { _('Register') }

    it_behaves_like 'password complexity validations'

    context 'when all password complexity rules are enabled' do
      include_context 'with all password complexity rules enabled'

      context 'when all rules are matched' do
        let(:password) { '12345aA.' }

        it 'creates the user' do
          visit path_to_visit

          fill_in_signup_form
          fill_in password_input_selector, with: password

          expect { click_button submit_button_selector }.to change { User.count }.by(1)
        end
      end
    end
  end

  context 'when reCAPTCHA is enabled' do
    before do
      stub_application_setting(recaptcha_enabled: true)
    end

    it 'creates the user' do
      visit new_user_registration_path
      fill_in_signup_form

      expect { click_button 'Register' }.to change { User.count }
    end

    context 'when reCAPTCHA verification fails' do
      before do
        allow_next_instance_of(RegistrationsController) do |instance|
          allow(instance).to receive(:verify_recaptcha).and_return(false)
        end
      end

      it 'does not create the user' do
        visit new_user_registration_path
        fill_in_signup_form

        expect { click_button 'Register' }.not_to change { User.count }
        expect(page).to have_content(_('There was an error with the reCAPTCHA. Please solve the reCAPTCHA again.'))
      end
    end
  end

  it_behaves_like 'creates a user with ArkoseLabs risk band' do
    let(:signup_path) { new_user_registration_path }
    let(:user_email) { new_user[:email] }

    subject(:fill_and_submit_signup_form) do
      fill_in_signup_form

      click_button "Register"
    end
  end
end
