# frozen_string_literal: true

module QA
  RSpec.describe 'Plan', :reliable, product_group: :project_management do
    describe 'Multiple assignees per issue' do
      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'project-to-test-issue-with-multiple-assignees'
        end
      end

      before do
        Flow::Login.sign_in

        user_1 = Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_username_1, Runtime::Env.gitlab_qa_password_1)
        user_2 = Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_username_2, Runtime::Env.gitlab_qa_password_2)
        user_3 = Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_username_3, Runtime::Env.gitlab_qa_password_3)
        user_4 = Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_username_4, Runtime::Env.gitlab_qa_password_4)
        user_5 = Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_username_5, Runtime::Env.gitlab_qa_password_5)
        user_6 = Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_username_6, Runtime::Env.gitlab_qa_password_6)

        project.add_member(user_1)
        project.add_member(user_2)
        project.add_member(user_3)
        project.add_member(user_4)
        project.add_member(user_5)
        project.add_member(user_6)

        @issue = Resource::Issue.fabricate_via_api! do |issue|
          issue.project = project
          issue.assignee_ids = [
            user_1.id,
            user_2.id,
            user_3.id,
            user_4.id,
            user_5.id,
            user_6.id
          ]
        end
      end

      it 'shows the first three assignees and a +n sign in the issues list', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347976' do
        project.visit!

        Page::Project::Menu.perform(&:go_to_issues)

        Page::Project::Issue::Index.perform do |index|
          expect(index).to have_assignee_link_count(3)
          expect(index.avatar_counter).to be_visible
          expect(index.avatar_counter).to have_content('+3')
        end
      end

      it 'shows the first five assignees and a +n more link in the issue page', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347977' do
        @issue.visit!

        Page::Project::Issue::Show.perform do |show|
          expect(show).to have_avatar_image_count(5)
          expect(show.more_assignees_link).to be_visible
          expect(show.more_assignees_link).to have_content('+ 1 more')

          show.toggle_more_assignees_link

          expect(show).to have_avatar_image_count(6)
          expect(show.more_assignees_link).to have_content('- show less')
        end
      end
    end
  end
end
