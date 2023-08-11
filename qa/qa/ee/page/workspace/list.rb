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

          def create_workspace(agent, project)
            click_element(:list_new_workspace_button, skip_finished_loading_check: true)

            QA::EE::Page::Workspace::New.perform do |new|
              new.select_devfile_project(project)
              new.select_cluster_agent(agent)
              new.save_workspace
            end
            Support::WaitForRequests.wait_for_requests(skip_finished_loading_check: true)
          end

          def get_workspaces_list
            all_elements(:workspace_list_item, minimum: 0, skip_finished_loading_check: true)
              .flat_map { |element| element.text.scan(/(^workspace[^.\n]*)/) }.flatten
          end

          def wait_for_workspaces_creation(workspace)
            within_element("#{workspace}_action".to_sym, skip_finished_loading_check: true) do
              Support::WaitForRequests.wait_for_requests(skip_finished_loading_check: false, finish_loading_wait: 180)
            end
          end

          def has_workspace_state?(workspace, state)
            within_element(workspace.to_s.to_sym, skip_finished_loading_check: true) do
              Support::Retrier.retry_until(sleep_interval: 5, max_attempts: 10) do
                has_element?("#{workspace}_actual_state".to_sym, title: state)
              end
            end
          end
        end
      end
    end
  end
end
