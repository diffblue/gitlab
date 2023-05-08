# frozen_string_literal: true

#   What does this test do
#
#   This is an e2e test that carries out all the operations necessary to create a new workspace from scratch.
#   In order to iterate upon this spec quickly, this first version doesnt manage/orchestrate KAS / agentk
#   / gitlab but expects them to be up and running.
#
#   How to setup the test
#
#   1. Ensure gitlab is up and running with default KAS / agentk stopped
#   2. Setup agentk and start agentk with the token received \
#   3. Call the helper scripts at `scripts/remote_development/run_e2e_spec.sh`

module QA
  RSpec.describe 'Create',
    quarantine: {
      type: :waiting_on,
      issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/389342'
    }, product_group: :editor do
    describe 'Remote Development' do
      let(:group) do
        QA::Resource::Sandbox.fabricate! do |sandbox|
          sandbox.path = ENV.fetch("AGENTK_GROUP", "gitlab-org")
        end
      end

      let(:new_workspace) do
        {
          desired_state: "Running",
          editor: "webide",
          cluster_agent: ENV.fetch("AGENTK_NAME", "test-agent")
        }
      end

      let(:devfile_project) do
        project = Resource::Project.fabricate_via_api! do |project|
          project.name = 'devfile-project'
          project.description = 'Project with a valid devfile'
          project.group = group
        end

        # TODO re-use the devfile created in other remote dev specs
        devfile_content = <<~YAML
          schemaVersion: 2.2.0
          components:
            - name: tooling-container
              attributes:
                gl/inject-editor: true
              container:
                image: quay.io/mloriedo/universal-developer-image:ubi8-dw-demo
        YAML

        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.add_files([{ file_path: '.devfile.yaml', content: devfile_content }])
        end

        project
      end

      before do
        Flow::Login.sign_in
      end

      after do
        unless new_workspace[:name].nil?
          EE::Flow::Workspace.terminate_workspace(
            group,
            new_workspace[:name]
          )
        end

        Flow::Project.archive_project(devfile_project) unless devfile_project.nil?
      end

      it 'creates a new workspace using a devfile from a project',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/396854' do
        existing_active_workspaces = EE::Flow::Workspace.get_active_workspaces(group)

        EE::Flow::Workspace.create_workspace(
          group,
          new_workspace[:cluster_agent],
          new_workspace[:desired_state],
          new_workspace[:editor],
          devfile_project.name
        )

        updated_active_workspaces = []

        # retry until the newly created workspace entry is listed in the workspace index page
        QA::Support::Retrier.retry_until(sleep_interval: 1, max_attempts: 30) do
          updated_active_workspaces = EE::Flow::Workspace.get_active_workspaces(group)

          (updated_active_workspaces - existing_active_workspaces).length == 1
        end

        new_workspace[:name] = (updated_active_workspaces - existing_active_workspaces)[0]

        QA::EE::Page::Workspace::Index.perform do |index|
          index.expect_workspace_to_have_state(
            new_workspace[:name],
            new_workspace[:desired_state]
          )
        end
      end
    end
  end
end
