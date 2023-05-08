# frozen_string_literal: true

module QA
  module EE
    module Page
      module Workspace
        class Index < QA::Page::Base
          # TODO: This needs to be update for the new UI. This view is a placeholder value added to make
          #       bundle exec bin/qa Test::Sanity::Selectors pass when the old UI was deleted.
          view 'ee/app/assets/javascripts/remote_development/pages/app.vue' do
            # element :new_workspace_button
            # element :workspace_data_loader
          end

          def click_new_workspace
            Support::Retrier.retry_until do
              click_element(:new_workspace_button)
              !has_element?(:new_workspace_button, wait: 0)
            end
          end

          def click_edit_button(workspace)
            edit_link = "workspace_#{workspace}_edit_link".to_sym
            click_element(edit_link)
          end

          def get_active_workspaces
            Support::Retrier.retry_until(sleep_interval: 5, max_attempts: 30) do
              all_elements(:workspace_data_loader, minimum: 0).empty?
            end

            all_elements(:active_workspace_name, minimum: 0).map(&:text)
          end

          def get_actual_state_of_workspace(workspace)
            element = "#{workspace}_actual_state".to_sym
            find_element(element).text
          end

          def expect_workspace_to_have_state(workspace, state)
            QA::Support::Retrier.retry_until(sleep_interval: 5, max_attempts: 30) do
              get_actual_state_of_workspace(workspace) == state
            end
          end
        end
      end
    end
  end
end
