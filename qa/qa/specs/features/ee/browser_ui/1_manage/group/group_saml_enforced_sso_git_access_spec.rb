# frozen_string_literal: true

module QA
  RSpec.describe 'Manage', :group_saml, :orchestrated, requires_admin: 'creates a user via API' do
    describe 'Group SAML SSO - Enforced SSO', product_group: :authentication_and_authorization do
      include Support::API

      let!(:group) do
        Resource::Sandbox.fabricate_via_api! do |sandbox_group|
          sandbox_group.path = "saml_sso_group_#{SecureRandom.hex(8)}"
        end
      end

      let!(:saml_idp_service) { Flow::Saml.run_saml_idp_service(group.path) }

      let!(:developer_user) { Resource::User.fabricate_via_api! }

      let!(:project) do
        Resource::Project.fabricate! do |project|
          project.name = 'project-in-saml-enforced-group'
          project.description = 'project in SAML enforced group for git clone test'
          project.group = group
          project.initialize_with_readme = true
        end
      end

      before do
        group.add_member(developer_user)

        Flow::Saml.enable_saml_sso(group, saml_idp_service, enforce_sso: true)

        Flow::Saml.logout_from_idp(saml_idp_service)

        page.visit Runtime::Scenario.gitlab_address
        Page::Main::Menu.perform(&:sign_out_if_signed_in)
      end

      it 'user clones and pushes to project within a group using Git HTTP', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347899' do
        expect do
          Resource::Repository::ProjectPush.fabricate! do |project_push|
            project_push.project = project
            project_push.branch_name = "new_branch"
            project_push.user = developer_user
          end
        end.not_to raise_error
      end

      after do
        page.visit Runtime::Scenario.gitlab_address

        group.remove_via_api!

        Page::Main::Menu.perform(&:sign_out_if_signed_in)

        Flow::Saml.remove_saml_idp_service(saml_idp_service)
      end
    end
  end
end
