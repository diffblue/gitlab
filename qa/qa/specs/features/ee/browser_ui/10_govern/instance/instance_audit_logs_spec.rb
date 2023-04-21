# frozen_string_literal: true

module QA
  # Issue to enable this test in live environments: https://gitlab.com/gitlab-org/quality/team-tasks/-/issues/614
  RSpec.describe 'Govern', :skip_live_env, product_group: :compliance do
    shared_examples 'audit event' do |expected_events|
      it 'logs audit events for UI operations' do
        sign_in

        Page::Main::Menu.perform(&:go_to_admin_area)
        QA::Page::Admin::Menu.perform(&:go_to_monitoring_audit_events)
        EE::Page::Admin::Monitoring::AuditLog.perform do |audit_log_page|
          expected_events.each do |expected_event|
            expect(audit_log_page).to have_audit_log_table_with_text(expected_event)
          end
        end
      end
    end

    describe 'Instance', :requires_admin do
      context 'for failed sign in', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347913' do
        before do
          Runtime::Browser.visit(:gitlab, Page::Main::Login)
          invalid_user = Resource::User.init do |user|
            user.username = 'bad_user_name'
            user.password = 'bad_pasword'
          end

          Page::Main::Login.perform do |login_page|
            login_page.sign_in_using_credentials(user: invalid_user, skip_page_validation: true)
          end
          sign_in
        end

        it_behaves_like 'audit event', ["Failed to login with STANDARD authentication"]
      end

      context 'for successful sign in', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347914' do
        before do
          sign_in
        end

        it_behaves_like 'audit event', ["Signed in with STANDARD authentication"]
      end

      context 'for add SSH key', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347915' do
        key = nil

        before do
          sign_in
          key = Resource::SSHKey.fabricate_via_browser_ui! do |resource|
            resource.title = "key for audit event test #{Time.now.to_f}"
          end
        end

        after do
          key&.reload!&.remove_via_api!
        end

        it_behaves_like 'audit event', ["Added SSH key"]
      end

      context 'for add and delete email',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347918' do
        before do
          sign_in

          new_email_address = Resource::User.new.email

          Page::Main::Menu.perform(&:click_edit_profile_link)
          Page::Profile::Menu.perform(&:click_emails)
          Support::Retrier.retry_until(sleep_interval: 3) do
            Page::Profile::Emails.perform do |emails|
              emails.add_email_address(new_email_address)
              expect(emails).to have_text(new_email_address) # rubocop:disable RSpec/ExpectInHook
              emails.delete_email_address(new_email_address)
              expect(emails).not_to have_text(new_email_address) # rubocop:disable RSpec/ExpectInHook
            end
          end
        end

        it_behaves_like 'audit event', ["Added email", "Removed email"]
      end

      context 'for change password', :skip_signup_disabled,
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347917' do
        before do
          user = Resource::User.fabricate_via_api! do |user|
            user.username = "user_#{SecureRandom.hex(4)}"
            user.password = "pw_#{SecureRandom.hex(4)}"
          end
          Runtime::Browser.visit(:gitlab, Page::Main::Login)

          Page::Main::Login.perform do |login_page|
            login_page.sign_in_using_credentials(user: user)
          end

          Page::Main::Menu.perform(&:click_edit_profile_link)
          Page::Profile::Menu.perform(&:click_password)
          Page::Profile::Password.perform do |password_page|
            password_page.update_password('new_password', user.password)
          end
          sign_in
        end

        it_behaves_like 'audit event', ["Changed password"]
      end

      context 'for start and stop user impersonation',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347916' do
        let!(:user_for_impersonation) { Resource::User.fabricate_via_api! }

        before do
          sign_in
          Page::Main::Menu.perform(&:go_to_admin_area)
          Page::Admin::Menu.perform(&:go_to_users_overview)
          Page::Admin::Overview::Users::Index.perform do |index|
            index.search_user(user_for_impersonation.username)
            index.click_user(user_for_impersonation.name)
          end

          Page::Admin::Overview::Users::Show.perform(&:click_impersonate_user)

          Page::Main::Menu.perform(&:click_stop_impersonation_link)
        end

        after do
          user_for_impersonation.remove_via_api!
        end

        it_behaves_like 'audit event', ["Started Impersonation", "Stopped Impersonation"]
      end

      def sign_in
        Page::Main::Menu.perform(&:sign_out_if_signed_in)
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.perform(&:sign_in_using_admin_credentials)
      end
    end
  end
end
