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
    let_it_be(:admin, freeze: true) { create(:user, :admin) }
    let(:new_user) { build(:user) }

    before do
      stub_application_setting(require_admin_approval_after_user_signup: false)
      stub_application_setting_enum('email_confirmation_setting', 'off')
      stub_application_setting(new_user_signups_cap: 3)

      visit new_user_registration_path
    end

    context 'when the cap has not been reached' do
      before do
        perform_enqueued_jobs do
          fill_in_sign_up_form(new_user)
        end
      end

      it 'does not send an approval email to the user', :sidekiq_inline do
        approval_email = ActionMailer::Base.deliveries.find { |m| m.subject == 'Welcome to GitLab!' }
        expect(approval_email).to eq(nil)
      end

      it 'does not send a notification email to the admin', :sidekiq_inline do
        password_reset_email = ActionMailer::Base.deliveries.find do |m|
          m.subject == 'Important information about usage on your GitLab instance'
        end

        expect(password_reset_email).to eq(nil)
      end
    end

    context 'when the cap has been reached' do
      before do
        create_list(:user, 2)
      end

      it 'sends notification email to the admin', :sidekiq_inline do
        perform_enqueued_jobs do
          fill_in_sign_up_form(new_user)
        end

        cap_reached_notification_email = ActionMailer::Base.deliveries.find do |m|
          m.subject == 'Important information about usage on your GitLab instance'
        end
        expect(cap_reached_notification_email.to).to eq([admin.email])
        expect(cap_reached_notification_email.text_part.body).to have_content(
          'Your GitLab instance has reached the maximum allowed user cap'
        )

        expect(ActionMailer::Base.deliveries.count).to eq(1)
      end
    end
  end
end
