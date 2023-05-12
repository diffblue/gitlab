# frozen_string_literal: true

module QA
  module EE
    module Page
      module Workspace
        class Action < QA::Page::Base
          view 'ee/app/assets/javascripts/remote_development/components/list/workspace_actions.vue' do
            element :workspace_button, ':data-qa-selector="`workspace_${action.key}_button`"' # rubocop:disable QA/ElementWithPattern
          end

          view 'ee/app/assets/javascripts/remote_development/components/list/workspaces_table.vue' do
            element :workspace_action, ':data-qa-selector="`${item.name}_action`"' # rubocop:disable QA/ElementWithPattern
          end

          def stop_workspace(workspace)
            within_element("#{workspace}_action".to_sym) do
              click_element(:workspace_stop_button)
              Support::Retrier.retry_until(sleep_interval: 5, max_attempts: 10) do
                !has_element?(:workspace_stop_button, wait: 0)
              end
            end
          end

          def terminate_workspace(workspace)
            within_element("#{workspace}_action".to_sym) do
              click_element(:workspace_terminate_button)
              Support::Retrier.retry_until(sleep_interval: 5, max_attempts: 10) do
                !has_element?(:workspace_terminate_button, wait: 0)
              end
            end
          end
        end
      end
    end
  end
end
