# frozen_string_literal: true

module QA
  module EE
    module Page
      module Workspace
        class Action < QA::Page::Base
          view 'ee/app/assets/javascripts/remote_development/components/common/workspace_actions.vue' do
            element :workspace_button, ':data-qa-selector="`workspace_${action.key}_button`"' # rubocop:disable QA/ElementWithPattern
          end

          view 'ee/app/assets/javascripts/remote_development/components/list/workspaces_table.vue' do
            element :workspace_action, ':data-qa-selector="`${item.name}_action`"' # rubocop:disable QA/ElementWithPattern
          end

          def click_workspace_action(workspace, action)
            within_element("#{workspace}_action".to_sym, skip_finished_loading_check: true) do
              click_element("workspace_#{action}_button", skip_finished_loading_check: true)
              Support::WaitForRequests.wait_for_requests(skip_finished_loading_check: false, finish_loading_wait: 180)
            end
          end
        end
      end
    end
  end
end
