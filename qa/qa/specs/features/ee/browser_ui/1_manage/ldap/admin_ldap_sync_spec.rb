# frozen_string_literal: true
module QA
  RSpec.describe 'Manage', :orchestrated, :ldap_no_server, product_group: :authentication_and_authorization do
    describe 'LDAP admin sync' do
      before do
        run_ldap_service_with_user_as('admin')

        Runtime::Browser.visit(:gitlab, Page::Main::Login)

        login_with_ldap_admin_user
      end

      it 'sets and removes user\'s admin status', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347896' do
        Page::Main::Menu.perform do |menu|
          admin_synchronised = menu.wait_until(max_duration: 80, sleep_interval: 1, reload: true) do
            menu.has_admin_area_link?
          end

          expect(admin_synchronised).to be_truthy
        end

        remove_ldap_service_with_user_as('admin')

        run_ldap_service_with_user_as('non_admin')

        login_with_ldap_admin_user

        Page::Main::Menu.perform do |menu|
          admin_removed = menu.wait_until(max_duration: 160, sleep_interval: 1, reload: true) do
            menu.has_no_admin_area_link?
          end

          expect(admin_removed).to be_truthy
        end
      end

      after do
        remove_ldap_service_with_user_as('non_admin')
      end

      def run_ldap_service_with_user_as(user_status)
        Service::DockerRun::LDAP.new(user_status).tap do |runner|
          runner.pull
          runner.register!
        end
      end

      def remove_ldap_service_with_user_as(user_status)
        Service::DockerRun::LDAP.new(user_status).remove!
      end

      def login_with_ldap_admin_user
        Page::Main::Login.perform do |login_page|
          user = Struct.new(:ldap_username, :ldap_password).new('adminuser1', 'password')

          QA::Support::Retrier.retry_until(raise_on_failure: true, sleep_interval: 3, max_attempts: 5) do
            login_page.sign_in_using_ldap_credentials(user: user)
          end
        end
      end
    end
  end
end
