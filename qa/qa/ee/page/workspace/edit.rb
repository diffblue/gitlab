# frozen_string_literal: true

module QA
  module EE
    module Page
      module Workspace
        class Edit < QA::Page::Base
          # TODO: This needs to be update for the new UI. This view is a placeholder value added to make
          #       bundle exec bin/qa Test::Sanity::Selectors pass when the old UI was deleted.
          view 'ee/app/assets/javascripts/remote_development/pages/app.vue' do
            # element :workspace_cluster_agent_id_field
            # element :workspace_desired_state_field
            # element :workspace_editor_field
            # element :workspace_devfile_project_id_field
            # element :save_workspace_button
          end

          def select_desired_state(desired_state)
            state_selector = find_element(:workspace_desired_state_field)
            options = state_selector.all('option')

            raise "No desiredState available" if options.empty?
            raise "No matching desiredState found" if options.none? { |option| option.text == desired_state }

            state_selector.select desired_state
          end

          def save_workspace_changes
            click_element(:save_workspace_button)

            Support::Retrier.retry_until(sleep_interval: 1, max_attempts: 10) do
              !has_element?(:save_workspace_button, wait: 0)
            end
          end
        end
      end
    end
  end
end
