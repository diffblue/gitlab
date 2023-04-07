# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Signup', feature_category: :system_access do
  context 'almost there page' do
    context 'when public visibility is restricted' do
      before do
        stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::PUBLIC])
      end

      it 'hides Explore link' do
        visit users_almost_there_path

        expect(page).to have_no_link("Explore")
      end

      it 'hides help link' do
        visit users_almost_there_path

        expect(page).to have_no_link("Help")
      end
    end
  end

  context 'with a user cap set', :js do
    let_it_be(:admin) { create(:user, :admin) }

    before do
      stub_application_setting_enum('email_confirmation_setting', 'off')
      stub_application_setting(new_user_signups_cap: 2)
    end

    def fill_in_sign_up_form
      fill_in 'new_user_username', with: 'bang'
      fill_in 'new_user_email', with: 'bigbang@example.com'
      fill_in 'new_user_first_name', with: 'Big'
      fill_in 'new_user_last_name', with: 'Bang'
      fill_in 'new_user_password', with: User.random_password
    end

    context 'when the cap has not been reached' do
      it 'sends a welcome email to the user and a notification email to the admin', :sidekiq_inline do
        visit new_user_registration_path

        fill_in_sign_up_form

        perform_enqueued_jobs do
          click_button 'Register'
        end

        email_to_user = ActionMailer::Base.deliveries.find { |m| m.to == ['bigbang@example.com'] }
        expect(email_to_user.subject).to have_content('Welcome to GitLab!')
        expect(email_to_user.text_part.body).to have_content('Your GitLab account request has been approved!')

        email_to_admin = ActionMailer::Base.deliveries.find { |m| m.to == [admin.email] }
        expect(email_to_admin.subject).to have_content('GitLab Account Request')
        expect(email_to_admin.text_part.body).to have_content('Big Bang has asked for a GitLab account')

        expect(ActionMailer::Base.deliveries.count).to eq(2)
      end
    end

    context 'when the cap has been reached' do
      before do
        create(:user)
      end

      it 'sends notification emails to the admin', :sidekiq_inline do
        visit new_user_registration_path

        fill_in_sign_up_form

        perform_enqueued_jobs do
          click_button 'Register'
        end

        signup_notification_email = ActionMailer::Base.deliveries.find { |m| m.subject == 'GitLab Account Request' }
        expect(signup_notification_email.to).to eq([admin.email])
        expect(signup_notification_email.text_part.body).to have_content('Big Bang has asked for a GitLab account')

        cap_reached_notification_email = ActionMailer::Base.deliveries.find do |m|
          m.subject == 'Important information about usage on your GitLab instance'
        end
        expect(cap_reached_notification_email.to).to eq([admin.email])
        expect(cap_reached_notification_email.text_part.body).to have_content(
          'Your GitLab instance has reached the maximum allowed user cap'
        )

        expect(ActionMailer::Base.deliveries.count).to eq(2)
      end
    end
  end
end
