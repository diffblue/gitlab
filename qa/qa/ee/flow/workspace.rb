# frozen_string_literal: true

module QA
  module EE
    module Flow
      module Workspace
        extend self

        def create_workspace(group, agent, state, editor, project)
          group.visit!

          QA::Page::Group::Menu.perform(&:go_to_workspaces)

          QA::EE::Page::Workspace::Index.perform(&:click_new_workspace)

          QA::EE::Page::Workspace::New.perform do |p|
            p.select_cluster_agent(agent)
            p.select_desired_state(state)
            p.set_editor(editor)
            p.select_devfile_project(project)

            p.confirm_workspace_creation
          end
        end

        def get_active_workspaces(group)
          group.visit!

          QA::Page::Group::Menu.perform(&:go_to_workspaces)

          QA::EE::Page::Workspace::Index.perform(&:get_active_workspaces)
        end

        def terminate_workspace(group, workspace)
          group.visit!

          QA::Page::Group::Menu.perform(&:go_to_workspaces)

          QA::EE::Page::Workspace::Index.perform do |index|
            index.click_edit_button(workspace)
          end

          QA::EE::Page::Workspace::Edit.perform do |edit|
            edit.select_desired_state("Terminated")
          end

          QA::EE::Page::Workspace::Edit.perform(&:save_workspace_changes)

          # wait until workspace disappears from Active workspaces tab
          QA::Support::Retrier.retry_until(sleep_interval: 5, max_attempts: 30) do
            active_workspaces = get_active_workspaces(group)
            active_workspaces.exclude? workspace
          end
        end
      end
    end
  end
end
