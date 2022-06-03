# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Signup on EE' do
  let(:new_user) { build_stubbed(:user) }

  before do
    stub_application_setting(require_admin_approval_after_user_signup: false)
  end

  def fill_in_signup_form
    fill_in 'new_user_username', with: new_user.username
    fill_in 'new_user_email', with: new_user.email
    fill_in 'new_user_first_name', with: new_user.first_name
    fill_in 'new_user_last_name', with: new_user.last_name
    fill_in 'new_user_password', with: new_user.password
  end

  context 'for Gitlab.com' do
    before do
      expect(Gitlab).to receive(:com?).and_return(true).at_least(:once)
      visit new_user_registration_path
    end

    context 'when the user sets it up for the company' do
      it 'creates the user and sets the email_opted_in field truthy' do
        fill_in_signup_form
        click_button "Register"

        select 'Software Developer', from: 'user_role'
        choose 'user_setup_for_company_true'
        click_button 'Continue'

        user = User.find_by_username!(new_user[:username])
        expect(user.email_opted_in).to be_truthy
        expect(user.email_opted_in_ip).to be_present
        expect(user.email_opted_in_source).to eq('GitLab.com')
        expect(user.email_opted_in_at).not_to be_nil
      end
    end

    context 'when the user checks the opt-in to email updates box' do
      it 'creates the user and sets the email_opted_in field truthy' do
        fill_in_signup_form
        click_button "Register"

        select 'Software Developer', from: 'user_role'
        choose 'user_setup_for_company_false'
        check 'user_email_opted_in'
        click_button 'Continue'

        user = User.find_by_username!(new_user[:username])
        expect(user.email_opted_in).to be_truthy
        expect(user.email_opted_in_ip).to be_present
        expect(user.email_opted_in_source).to eq('GitLab.com')
        expect(user.email_opted_in_at).not_to be_nil
      end
    end

    context 'when the user does not check the opt-in to email updates box' do
      it 'creates the user and sets the email_opted_in field falsey' do
        fill_in_signup_form
        click_button "Register"

        select 'Software Developer', from: 'user_role'
        choose 'user_setup_for_company_false'
        click_button 'Continue'

        user = User.find_by_username!(new_user[:username])
        expect(user.email_opted_in).to be_falsey
        expect(user.email_opted_in_ip).to be_blank
        expect(user.email_opted_in_source).to be_blank
        expect(user.email_opted_in_at).to be_nil
      end
    end

    context 'when the user_other_role_details feature flag is disabled' do
      before do
        stub_feature_flags(user_other_role_details: false)
      end

      context 'collects no collect a job title' do
        it 'proceeds to the next step without collecting other_role' do
          fill_in_signup_form
          click_button "Register"

          select 'Other', from: 'user_role'
          expect(page).not_to have_field('What is your job title? (optional)')
          choose 'user_setup_for_company_false'
          click_button 'Continue'

          user = User.find_by_username!(new_user[:username])
          expect(user.other_role).to be_blank
        end
      end
    end

    context 'when the user selects existing role' do
      let_it_be(:job_title) { 'Guardian of the galaxy' }

      it 'has the job title box' do
        expect(page).not_to have_field('What is your job title? (optional)')
      end

      it 'proceeds to the next step' do
        fill_in_signup_form
        click_button "Register"

        select 'Software Developer', from: 'user_role'
        choose 'user_setup_for_company_false'
        click_button 'Continue'

        user = User.find_by_username!(new_user[:username])
        expect(user.other_role).to be_blank
      end
    end

    context 'when the user selects other role' do
      let_it_be(:job_title) { 'Guardian of the galaxy' }

      it 'has the job title box' do
        expect(page).not_to have_field('What is your job title? (optional)')
      end

      it 'proceeds to the next step' do
        fill_in_signup_form
        click_button "Register"

        select 'Other', from: 'user_role'
        expect(page).to have_field('What is your job title? (optional)')

        choose 'user_setup_for_company_false'
        fill_in 'What is your job title? (optional)', with: job_title

        click_button 'Continue'

        user = User.find_by_username!(new_user[:username])
        expect(user.other_role).to eq(job_title)
      end
    end

    it 'redirects to step 2 of the signup process when not completed' do
      fill_in_signup_form
      click_button 'Register'
      visit new_project_path

      expect(page).to have_current_path(users_sign_up_welcome_path)

      select 'Software Developer', from: 'user_role'
      choose 'user_setup_for_company_true'
      click_button 'Continue'
      user = User.find_by_username(new_user[:username])

      expect(user.software_developer_role?).to be_truthy
      expect(user.setup_for_company).to be_truthy
    end
  end

  context 'not for Gitlab.com' do
    before do
      expect(Gitlab).to receive(:com?).and_return(false).at_least(:once)
      visit new_user_registration_path
    end

    it 'does not have a opt-in checkbox, it creates the user and sets email_opted_in to falsey' do
      expect(page).not_to have_selector("[name='new_user_email_opted_in']")

      fill_in_signup_form
      click_button "Register"

      user = User.find_by_username!(new_user[:username])
      expect(user.email_opted_in).to be_falsey
      expect(user.email_opted_in_ip).to be_blank
      expect(user.email_opted_in_source).to be_blank
      expect(user.email_opted_in_at).to be_nil
    end

    it 'redirects to step 2 of the signup process when not completed and redirects back' do
      fill_in_signup_form
      click_button 'Register'
      visit new_project_path

      expect(page).to have_current_path(users_sign_up_welcome_path)

      select 'Software Developer', from: 'user_role'
      click_button 'Get started!'

      expect(page).to have_current_path(new_project_path)
    end
  end
end
