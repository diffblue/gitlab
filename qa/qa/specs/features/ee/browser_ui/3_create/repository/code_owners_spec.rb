# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Codeowners', product_group: :source_code do
      let(:files) do
        [
          {
            name: 'file.txt',
            content: 'foo'
          },
          {
            name: 'README.md',
            content: 'bar'
          }
        ]
      end

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = "codeowners"
        end
      end

      let(:user) do
        Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_username_1, Runtime::Env.gitlab_qa_password_1)
      end

      let(:user2) do
        Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_username_2, Runtime::Env.gitlab_qa_password_2)
      end

      before do
        Flow::Login.sign_in

        project.visit!

        Page::Project::Menu.perform(&:click_members)
        Page::Project::Members.perform do |members_page|
          members_page.add_member(user.username)
          members_page.add_member(user2.username)
        end
      end

      it 'displays owners specified in CODEOWNERS file',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347763' do
        codeowners_file_content =
          <<-CONTENT
            * @#{user2.username}
            *.txt @#{user.username}
          CONTENT
        files << {
          name: 'CODEOWNERS',
          content: codeowners_file_content
        }

        # Push CODEOWNERS and test files to the project
        Resource::Repository::ProjectPush.fabricate! do |push|
          push.project = project
          push.files = files
          push.commit_message = 'Add CODEOWNERS and test files'
        end
        project.visit!

        # Check the files and code owners
        Page::Project::Show.perform { |project_page| project_page.click_file 'file.txt' }
        Page::File::Show.perform(&:reveal_code_owners)

        expect(page).to have_content(user.name)
        expect(page).not_to have_content(user2.name)

        project.visit!
        Page::Project::Show.perform { |project_page| project_page.click_file 'README.md' }
        Page::File::Show.perform(&:reveal_code_owners)

        expect(page).to have_content(user2.name)
        expect(page).not_to have_content(user.name)
      end
    end
  end
end
