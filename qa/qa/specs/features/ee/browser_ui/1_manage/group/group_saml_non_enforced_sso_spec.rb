# frozen_string_literal: true

module QA
  RSpec.describe 'Manage', :group_saml, :orchestrated, requires_admin: 'creates a user via API' do
    describe 'Group SAML SSO - Non enforced SSO', product_group: :authentication_and_authorization do
      include Support::API

      let(:user) { Resource::User.fabricate_via_api! }

      before(:all) do
        @group = Resource::Sandbox.fabricate_via_api! do |sandbox_group|
          sandbox_group.path = "saml_sso_group_#{SecureRandom.hex(8)}"
        end

        @saml_idp_service = Flow::Saml.run_saml_idp_service(@group.path)
      end

      before do
        Flow::Saml.logout_from_idp(@saml_idp_service)

        page.visit Runtime::Scenario.gitlab_address
        Page::Main::Menu.perform(&:sign_out_if_signed_in)

        Flow::Login.sign_in
      end

      context 'when SAML SSO is configured with a default membership role' do
        let(:default_membership_role) { 'Developer' }

        it 'adds the new member with access level as set in SAML SSO configuration', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347936' do
          managed_group_url = Flow::Saml.enable_saml_sso(@group, @saml_idp_service, default_membership_role: default_membership_role)
          Page::Main::Menu.perform(&:sign_out_if_signed_in)

          Flow::Login.while_signed_in(as: user) do
            page.visit managed_group_url
            EE::Page::Group::SamlSSOSignIn.perform(&:click_sign_in)
            Flow::Saml.login_to_idp_if_required('user3', 'user3pass')

            expect(page).to have_content("Your organization's SSO has been connected to your GitLab account")

            member_details = @group.list_members.find { |item| item[:username] == user.username }

            expect(member_details[:access_level]).to eq(Resource::Members::AccessLevel::DEVELOPER)
          end
        end
      end

      it 'user logs in to group with SAML SSO', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347897' do
        managed_group_url = Flow::Saml.enable_saml_sso(@group, @saml_idp_service)

        Flow::Login.while_signed_in(as: user) do
          page.visit managed_group_url

          EE::Page::Group::SamlSSOSignIn.perform(&:click_sign_in)

          Flow::Saml.login_to_idp_if_required('user1', 'user1pass')

          expect(page).to have_content("Your organization's SSO has been connected to your GitLab account")

          page.visit managed_group_url

          expect(page).to have_content("Already signed in with SAML for #{@group.path}")
        end
      end

      it 'lets group admin test settings', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347898' do
        incorrect_fingerprint = Digest::SHA1.hexdigest(rand.to_s)

        Flow::Saml.visit_saml_sso_settings(@group)

        EE::Page::Group::Settings::SamlSSO.perform do |saml_sso|
          saml_sso.set_id_provider_sso_url(@saml_idp_service.idp_sso_url)
          saml_sso.set_cert_fingerprint(incorrect_fingerprint)
          saml_sso.click_save_changes

          saml_sso.click_test_button
        end

        Flow::Saml.login_to_idp_if_required('user2', 'user2pass')

        expect(page).to have_content("Verify SAML Configuration")
        expect(page).to have_content("Fingerprint mismatch")
        expect(page).to have_content("<saml:Issuer>#{@saml_idp_service.idp_issuer}</saml:Issuer>")

        EE::Page::Group::Settings::SamlSSO.perform do |saml_sso|
          saml_sso.set_cert_fingerprint(@saml_idp_service.idp_certificate_fingerprint)
          saml_sso.click_save_changes

          saml_sso.click_test_button
        end

        expect(page).to have_content("Verify SAML Configuration")
        expect(page).not_to have_content("Fingerprint mismatch")
      end

      after do
        user.remove_via_api! if user
      end

      after(:all) do
        @group.remove_via_api!

        page.visit Runtime::Scenario.gitlab_address
        Page::Main::Menu.perform(&:sign_out_if_signed_in)

        Flow::Saml.remove_saml_idp_service(@saml_idp_service)
      end
    end
  end
end
