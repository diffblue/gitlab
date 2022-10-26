# frozen_string_literal: true

module QA
  RSpec.describe 'Verify' do
    describe 'Cancelling merge request in merge train', :runner, :requires_admin, product_group: :pipeline_execution do
      context 'when user cancels the merge request' do
        include_context 'merge train spec with user prep'

        it(
          'does not create a TODO task',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347665'
        ) do
          # Manually removes merge request from the train
          Page::MergeRequest::Show.perform do |show|
            show.wait_until(reload: false) do
              show.has_content? 'started a merge train'
            end

            show.cancel_auto_merge!

            expect(show).to have_system_note('removed this merge request from the merge train')
          end

          Page::Main::Menu.perform do |main|
            main.go_to_page_by_shortcut(:todos_shortcut_button)
          end

          Page::Dashboard::Todos.perform do |todos|
            expect(todos).to have_no_todo_list, 'This user should not have any to-do item but found at least one!'
          end
        end
      end
    end
  end
end
