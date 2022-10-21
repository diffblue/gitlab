# frozen_string_literal: true

module QA
  RSpec.describe 'Plan', :reliable, product_group: :project_management do
    describe 'Custom email', :requires_admin do
      before do
        Flow::Login.sign_in_as_admin
        Page::Main::Menu.perform(&:go_to_admin_area)
        Page::Admin::Menu.perform(&:go_to_preferences_settings)
      end

      it 'customizes email with additional text', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347951' do
        random_custom_text = "Testing custom email - #{SecureRandom.hex(8)}"

        EE::Page::Admin::Settings::Preferences.perform do |preferences|
          preferences.expand_email_settings do |email_settings|
            email_settings.fill_additional_text(random_custom_text)
            email_settings.save_changes

            expect(email_settings.additional_text_textarea_text).to have_content(random_custom_text)
          end
        end
      end
    end
  end
end
