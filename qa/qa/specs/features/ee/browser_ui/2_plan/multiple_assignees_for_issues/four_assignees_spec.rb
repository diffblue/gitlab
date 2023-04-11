# frozen_string_literal: true

module QA
  RSpec.describe 'Plan', :reliable, product_group: :project_management do
    describe 'Multiple assignees per issue' do
      before do
        Flow::Login.sign_in

        user_1 = Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_username_1, Runtime::Env.gitlab_qa_password_1)
        user_2 = Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_username_2, Runtime::Env.gitlab_qa_password_2)
        user_3 = Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_username_3, Runtime::Env.gitlab_qa_password_3)
        user_4 = Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_username_4, Runtime::Env.gitlab_qa_password_4)

        project = Resource::Project.fabricate_via_api! do |project|
          project.name = 'project-to-test-issue-with-multiple-assignees'
        end

        project.add_member(user_1)
        project.add_member(user_2)
        project.add_member(user_3)
        project.add_member(user_4)

        Resource::Issue.fabricate_via_api! do |issue|
          issue.project = project
          issue.assignee_ids = [
            user_1.id,
            user_2.id,
            user_3.id,
            user_4.id
          ]
        end

        project.visit!
      end

      it 'shows four assignees in the issues list', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347960' do
        Page::Project::Menu.perform(&:go_to_issues)

        Page::Project::Issue::Index.perform do |index|
          expect(index).to have_assignee_link_count(4)
        end
      end
    end
  end
end
