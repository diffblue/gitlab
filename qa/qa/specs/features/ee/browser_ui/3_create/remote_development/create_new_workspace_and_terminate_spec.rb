# frozen_string_literal: true

#   What does this test do
#
#   This is an e2e test that carries out all the operations necessary to create a new workspace from scratch ideally.
#   But, In order to iterate upon this spec quickly, this first version doesnt manage/orchestrate KAS / agentk
#   / gitlab but expects them to be up and running.
#
#   How to setup the test
#
#   1. Ensure gitlab is up and running with default KAS / agentk stopped
#   2. Setup agentk for a group and start agentk with the token received.
#        (This agent name is passed in variable AGENTK_NAME)
#   3. Add a project under the same group and add a file named .devfile.yaml with below content.
#        (This project name is passed in variable DEVFILE_PROJECT)
#         devfile_content = <<~YAML
#            schemaVersion: 2.2.0
#              components:
#                - name: tooling-container
#                attributes:
#                  gl/inject-editor: true
#                  container:
#                    image: quay.io/mloriedo/universal-developer-image:ubi8-dw-demo
#          YAML
#   4. Call the helper scripts at `scripts/remote_development/run_e2e_spec.sh` with DEVFILE_PROJECT and AGENTK_NAME
#      For example, to override any variable, the script can be run in the following manner
#         DEVFILE_PROJECT="devfile-test-project" AGENTK_NAME="test-agent" GITLAB_PASSWORD=example
#         TEST_INSTANCE_URL=https://gdk.test:3000 scripts/remote_development/run-e2e-spec.sh

module QA
  RSpec.describe 'Create',
    quarantine: {
      type: :waiting_on,
      issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/397005'
    }, product_group: :ide do
    describe 'Remote Development' do
      let(:devfile_project_name) { ENV.fetch("DEVFILE_PROJECT", "devfile-project-example") }
      let(:agent) { ENV.fetch("AGENTK_NAME", "test-agentk") }

      before do
        Flow::Login.sign_in
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
