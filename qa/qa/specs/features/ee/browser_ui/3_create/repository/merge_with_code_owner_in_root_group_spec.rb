# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Codeowners' do
      context 'when the project is in the root group', :requires_admin, product_group: :source_code do
        let(:approver) do
          Resource::User.fabricate_via_api! do |resource|
            resource.api_client = Runtime::API::Client.as_admin
          end
        end

        let(:root_group) { Resource::Sandbox.fabricate_via_api! }
        let(:project) do
          Resource::Project.fabricate_via_api! do |project|
            project.group = root_group
            project.name = "code-owner-approve-and-merge"
            project.initialize_with_readme = true
          end
        end

        before do
          group_or_project.add_member(approver, Resource::Members::AccessLevel::MAINTAINER)

          Flow::Login.sign_in

          project.visit!
        end

        after do
          group_or_project.remove_member(approver)
          approver.remove_via_api!
          project.remove_via_api!
        end

        context 'and the code owner is the root group', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347804' do
          let(:codeowner) { root_group.path }
          let(:group_or_project) { root_group }

          it_behaves_like 'code owner merge request'
        end

        context 'and the code owner is a user', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347805' do
          let(:codeowner) { approver.username }
          let(:group_or_project) { project }

          it_behaves_like 'code owner merge request'
        end
      end
    end
  end
end
