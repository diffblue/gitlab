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

      let(:codeowners_file_content) do
        <<-CONTENT
            * @#{user2.username}
            *.txt @#{user.username}
        CONTENT
      end

      before do
        Flow::Login.sign_in

        project.add_member(user)
        project.add_member(user2)

        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.commit_message = 'Add CODEOWNERS and test files'
          commit.add_files([
            { file_path: 'file.txt', content: 'foo' },
            { file_path: 'README.md', content: 'bar' },
            { file_path: 'CODEOWNERS', content: codeowners_file_content }
          ])
        end
      end

      it 'displays owners specified in CODEOWNERS file',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347763' do
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
