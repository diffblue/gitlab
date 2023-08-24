# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Codeowners' do
      context 'when the project is in a subgroup', :requires_admin, product_group: :source_code do
        let(:approver) { create(:user, api_client: Runtime::API::Client.as_admin) }

        let(:project) { create(:project, :with_readme, name: 'approve-and-merge') }

        before do
          group_or_project.add_member(approver, Resource::Members::AccessLevel::MAINTAINER)

          Flow::Login.sign_in

          project.visit!
        end

        after do
          group_or_project.remove_member(approver)
          approver.remove_via_api!
        end

        context 'and the code owner is the root group', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347801' do
          let(:codeowner) { project.group.sandbox.path }
          let(:group_or_project) { project.group.sandbox }

          it_behaves_like 'code owner merge request'
        end

        context 'and the code owner is the subgroup', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347802' do
          let(:codeowner) { project.group.full_path }
          let(:group_or_project) { project.group }

          it_behaves_like 'code owner merge request'
        end

        context 'and the code owner is a user', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347800' do
          let(:codeowner) { approver.username }
          let(:group_or_project) { project }

          it_behaves_like 'code owner merge request'
        end
      end
    end
  end
end
