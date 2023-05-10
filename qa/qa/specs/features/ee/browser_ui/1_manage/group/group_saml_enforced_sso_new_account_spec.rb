# frozen_string_literal: true

module QA
  RSpec.describe 'Manage', :group_saml, :orchestrated, requires_admin: 'for various user admin functions' do
    describe 'Group SAML SSO - Enforced SSO', product_group: :authentication_and_authorization do
      include Support::API

      let!(:group) do
        Resource::Sandbox.fabricate_via_api! do |sandbox_group|
          sandbox_group.path = "saml_sso_group_#{SecureRandom.hex(8)}"
          sandbox_group.visibility = :private
        end
      end

      let(:idp_user) { Struct.new(:username, :password).new('user3', 'user3pass') }

      # The user that signs in via the IDP with username `user3` and password `user3pass`
      # will have `user_3` as username in GitLab
      let(:user) do
        QA::Resource::User.init do |user|
          user.username = 'user_3'
          user.email = 'user_3@example.com'
          user.name = 'User Three'
        end
      end

      let!(:saml_idp_service) { Flow::Saml.run_saml_idp_service(group.path) }

      let!(:group_sso_url) { Flow::Saml.enable_saml_sso(group, saml_idp_service, enforce_sso: true) }

      before do
        Page::Main::Menu.perform(&:sign_out_if_signed_in)

        Flow::Saml.logout_from_idp(saml_idp_service)
      end

      shared_examples 'group membership actions' do
        before do
          remove_user if user.exists?
        end

        it 'creates a new account automatically and allows to leave group and join again' do
          # When the user signs in via IDP for the first time

          group.visit!

          EE::Page::Group::SamlSSOSignIn.perform(&:click_sign_in)

          Flow::Saml.login_to_idp_if_required(idp_user.username, idp_user.password)

          expect(page).to have_text("Signed in with SAML")

          Page::Group::Show.perform(&:leave_group)

          expect(page).to have_text("You left")

          Page::Main::Menu.perform(&:sign_out)

          Flow::Saml.logout_from_idp(saml_idp_service)

          # When the user exists with a linked identity

          visit_group_sso_url

          EE::Page::Group::SamlSSOSignIn.perform(&:click_sign_in)

          Flow::Saml.login_to_idp_if_required(idp_user.username, idp_user.password)

          expect(page).to have_text(
            "Sign in with your existing credentials to connect your organization's account"
          )

          Flow::Saml.logout_from_idp(saml_idp_service)

          # When the user is removed and so their linked identity is also removed

          remove_user

          visit_group_sso_url

          EE::Page::Group::SamlSSOSignIn.perform(&:click_sign_in)

          Flow::Saml.login_to_idp_if_required(idp_user.username, idp_user.password)

          expect(page).to have_text("Signed in with SAML")
        end
      end

      context 'with Snowplow tracking enabled', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347675' do
        before do
          Flow::Settings.enable_snowplow
        end

        it_behaves_like 'group membership actions'

        after do
          Flow::Settings.disable_snowplow
        end
      end

      context 'with Snowplow tracking disabled', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/351257' do
        before do
          Flow::Settings.disable_snowplow
        end

        it_behaves_like 'group membership actions'
      end

      after do
        Flow::Saml.remove_saml_idp_service(saml_idp_service)

        group.remove_via_api!

        remove_user

        page.visit Runtime::Scenario.gitlab_address
        Page::Main::Menu.perform(&:sign_out_if_signed_in)
      end
    end

    private

    def remove_user
      user.reload!
      user.remove_via_api!
      Support::Waiter.wait_until(max_duration: 180, retry_on_exception: true, sleep_interval: 3) { !user.exists? }
    end

    def visit_group_sso_url
      Runtime::Logger.info(%(Visiting managed_group_url at "#{group_sso_url}"))

      page.visit group_sso_url
      Support::Waiter.wait_until { current_url == group_sso_url }
    end
  end
end
