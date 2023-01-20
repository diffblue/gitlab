# frozen_string_literal: true

module QA
  RSpec.describe 'Verify' do
    describe 'Cancelling merge request in merge train', :runner, :requires_admin, product_group: :pipeline_execution do
      context 'when system cancels the merge request' do
        include_context 'merge train spec with user prep'

        it(
          'creates a TODO task',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347666',
          quarantine: {
            issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/324122',
            type: :bug
          }
        ) do
          # Create a merge conflict
          Resource::Repository::Commit.fabricate_via_api! do |commit|
            commit.project = project
            commit.commit_message = 'changing text file'
            commit.update_files(
              [
                {
                  file_path: file_name,
                  content: 'Has to be different than before.'
                }
              ]
            )
          end

          Page::MergeRequest::Show.perform do |show|
            expect(show).to have_system_note('removed this merge request from the merge train')
          end

          Page::Main::Menu.perform do |main|
            main.go_to_page_by_shortcut(:todos_shortcut_button)
          end

          Page::Dashboard::Todos.perform do |todos|
            todos.wait_until(reload: true, sleep_interval: 1) { todos.has_todo_list? }

            expect(todos).to have_latest_todo_with_title(title: mr_title, action: "Removed from Merge Train")
          end
        end
      end
    end
  end
end
