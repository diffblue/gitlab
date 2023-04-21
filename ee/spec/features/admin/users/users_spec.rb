# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin::Users', feature_category: :user_profile do
  include Features::AdminUsersHelpers
  include Spec::Support::Helpers::ModalHelpers

  let_it_be(:admin) { create(:admin) }
  let(:user) { create(:user) }

  before do
    sign_in(admin)
    gitlab_enable_admin_mode_sign_in(admin)
  end

  describe 'GET /admin/users/edit' do
    let(:path_to_visit) { edit_admin_user_path(user) }
    let(:submit_button_selector) { _('Save changes') }

    describe 'password complexity', :js do
      let(:password_input_selector) { :user_password }

      it 'does not render any rule' do
        visit path_to_visit

        expect(page).not_to have_selector('[data-testid="password-rule-text"]')
      end

      context 'when all password complexity rules are enabled' do
        include_context 'with all password complexity rules enabled'
        let(:password) { '12345aA.' }

        it 'updates user password' do
          visit path_to_visit

          expect(page).to have_selector('[data-testid="password-rule-text"]', count: 0)

          fill_in :user_password, with: password
          fill_in :user_password_confirmation, with: password

          expect(page).to have_selector('[data-testid="password-rule-text"]', count: 4)

          click_button submit_button_selector

          expect(page).to have_content(_('User was successfully updated.'))
          expect(page).to have_current_path(admin_user_path(user), ignore_query: true)
        end

        context 'without filling password' do
          let(:new_user_name) { FFaker::Name.name }

          it 'allows admin to update user info' do
            visit path_to_visit

            expect(page).to have_selector('[data-testid="password-rule-text"]', count: 0)

            fill_in 'user_name', with: new_user_name
            click_button submit_button_selector

            expect(page).to have_content(_('User was successfully updated.'))
            expect(page).to have_content(new_user_name)
            expect(page).to have_current_path(admin_user_path(user), ignore_query: true)
          end
        end
      end
    end

    describe 'editing custom attributes' do
      let!(:custom_attribute) do
        create(:user_custom_attribute,
          key: attribute,
          value: Arkose::VerifyResponse::RISK_BAND_MEDIUM,
          user: user
        )
      end

      context 'when user has a non-editable custom attribute' do
        let(:attribute) { 'bread_provider' }

        it 'does not allow the admin to update the custom attribute' do
          visit path_to_visit

          expect(page).to have_selector('#user_custom_attributes_attributes_0_value', count: 0)
        end
      end

      context 'when user has an editable custom attribute' do
        let(:attribute) { UserCustomAttribute::ARKOSE_RISK_BAND }

        it 'allows the admin to update the custom attribute' do
          visit path_to_visit
          select(Arkose::VerifyResponse::RISK_BAND_LOW, from: UserCustomAttribute::ARKOSE_RISK_BAND)
          click_button submit_button_selector

          expect(page).to have_content(_('User was successfully updated.'))
          expect(page).to have_content(Arkose::VerifyResponse::RISK_BAND_LOW)
        end
      end
    end
  end

  describe 'GET /admin/users/new', :js do
    def fill_in_new_user_form
      fill_in 'user_name', with: 'Big Bang'
      fill_in 'user_username', with: 'bang'
      fill_in 'user_email', with: 'bigbang@mail.com'
    end

    context 'with a user cap set' do
      before do
        stub_application_setting(new_user_signups_cap: 2)
      end

      context 'when the cap has not been reached' do
        it 'sends an approval email and a password reset email to the user', :sidekiq_inline do
          visit new_admin_user_path

          fill_in_new_user_form

          perform_enqueued_jobs do
            click_button 'Create user'
          end

          welcome_email = ActionMailer::Base.deliveries.find { |m| m.subject == 'Welcome to GitLab!' }
          expect(welcome_email.to).to eq(['bigbang@mail.com'])
          expect(welcome_email.text_part.body).to have_content('Your GitLab account request has been approved!')

          password_reset_email = ActionMailer::Base.deliveries.find { |m| m.subject == 'Account was created for you' }
          expect(password_reset_email.to).to eq(['bigbang@mail.com'])
          expect(password_reset_email.text_part.body).to have_content('Click here to set your password')

          expect(ActionMailer::Base.deliveries.count).to eq(2)
        end
      end

      context 'when the cap has been reached' do
        before do
          user
        end

        it 'sends a notification email to the admin', :sidekiq_inline do
          visit new_admin_user_path

          fill_in_new_user_form

          perform_enqueued_jobs do
            click_button 'Create user'
          end

          email = ActionMailer::Base.deliveries.last
          expect(email.to).to eq([admin.email])
          expect(email.subject).to eq('Important information about usage on your GitLab instance')
          expect(email.text_part.body).to have_content('Your GitLab instance has reached the maximum allowed user cap')

          expect(ActionMailer::Base.deliveries.count).to eq(1)
        end
      end
    end
  end
end
