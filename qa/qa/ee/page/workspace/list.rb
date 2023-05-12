# frozen_string_literal: true

module QA
  module EE
    module Page
      module Workspace
        class List < QA::Page::Base
          view 'ee/app/assets/javascripts/remote_development/components/list/empty_state.vue' do
            element :empty_new_workspace_button
          end

          view 'ee/app/assets/javascripts/remote_development/pages/list.vue' do
            element :list_new_workspace_button
            element :workspace_list_item
          end

          view 'ee/app/assets/javascripts/remote_development/components/list/workspaces_table.vue' do
            element :workspace_actual_state, ':data-qa-selector="`${item.name}_actual_state`"' # rubocop:disable QA/ElementWithPattern
          end

          def has_empty_workspace?
            has_element?(:empty_new_workspace_button)
          end

          def click_new_workspace_button
            Support::Retrier.retry_until do
              click_element(:list_new_workspace_button)
              !has_element?(:list_new_workspace_button, wait: 0)
            end
          end

          def create_workspace(agent, project)
            click_new_workspace_button

            QA::EE::Page::Workspace::New.perform do |p|
              p.select_devfile_project(project)
              p.select_cluster_agent(agent)
              p.confirm_workspace_creation
            end
          end

          def get_workspaces_list
            return if has_element?(:empty_new_workspace_button, wait: 0)

            all_elements(:workspace_list_item,
              minimum: 0).map { |element| element.text.match(/(workspace\S+)/)[1] }
          end

          def has_workspace_state?(workspace, state)
            Support::Retrier.retry_until(sleep_interval: 5, max_attempts: 10) do
              has_element?("#{workspace}_actual_state".to_sym, title: state)
            end
          end
        end
      end
    end
  end
end
