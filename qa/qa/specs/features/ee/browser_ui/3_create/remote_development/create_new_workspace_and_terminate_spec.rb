# frozen_string_literal: true

#   What does this test do
#
#   This is an e2e test that carries out all the operations necessary to create a new workspace from scratch ideally.
#   But, In order to iterate upon this spec quickly, this first version doesnt manage/orchestrate KAS / agentk
#   / gitlab but expects them to be up and running.
#
#   How to setup the test
#
#   1. Follow this documentation to set up your local GDK environment for creating remote development workspaces:
#      https://gitlab.com/gitlab-org/remote-development/gitlab-remote-development-docs/-/blob/main/doc/local-development-environment-setup.md
#   2. Ensure that you can successfully create and terminate workspaces in your local GDK environment.
#   3. Call the helper script at `scripts/remote_development/run-e2e-tests.sh`.
#      If you used all the default suggested group/project/agent values in the documentation above, the default values
#      should work for you. Otherwise, any variable can be overridden on the command line, for example:
#
#      DEVFILE_PROJECT="devfile-test-project" AGENT_NAME="test-agent" scripts/remote_development/run-e2e-tests.sh

module QA
  RSpec.describe 'Create',
    quarantine: {
      type: :waiting_on,
      issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/397005'
    }, product_group: :ide do
    describe 'Remote Development' do
      let(:devfile_project_name) { ENV.fetch("DEVFILE_PROJECT", "devfile-project-example") }
      let(:agent) { ENV.fetch("AGENT_NAME", "test-agent") }

      before do
        Flow::Login.sign_in(skip_page_validation: true)
      end

      it 'creates a new workspace and then stops and terminates it',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/396854' do
        QA::Page::Main::Menu.perform(&:go_to_workspaces)
        workspace_name = ""

        QA::EE::Page::Workspace::List.perform do |list|
          list.get_workspaces_list
          list.create_workspace(agent, devfile_project_name)
          workspaces_list = list.get_workspaces_list
          workspace_name = workspaces_list[0].to_s if workspaces_list.length >= 1
          expect(list).to have_workspace_state(workspace_name, "Running")
        end

        QA::EE::Page::Workspace::Action.perform do |workspace|
          workspace.stop_workspace(workspace_name)
        end

        QA::EE::Page::Workspace::List.perform do |list_item|
          expect(list_item).to have_workspace_state(workspace_name, "Stopped")
        end

        QA::EE::Page::Workspace::Action.perform do |workspace|
          workspace.terminate_workspace(workspace_name)
        end
        QA::EE::Page::Workspace::List.perform do |list_item|
          expect(list_item).to have_workspace_state(workspace_name, "Terminated")
        end
      end
    end
  end
end
