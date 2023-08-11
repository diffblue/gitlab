# frozen_string_literal: true

#   What does this test do
#
#   This is an e2e test that doesnt manage / orchestrate KAS / agentk / gitlab but expects them to be up and running.
#   This test is currently quarantined and its used for local testing by the engineers
#   This can be removed in the fututre when we have a better approach for local testing
#
#   How to setup the test
#
#   1. Follow this documentation to set up your local GDK environment for creating remote development workspaces:
#      https://gitlab.com/gitlab-org/remote-development/gitlab-remote-development-docs/-/blob/main/doc/local-development-environment-setup.md
#   2. Ensure that you can successfully create and terminate workspaces in your local GDK environment. (It can also be
#      run against other environments if the setup for remote dev agent and devfile project has been setup already)
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
      context 'when prerequisite is already done',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/396854' do
        let!(:kubernetes_agent) do
          Resource::Clusters::Agent.init do |agent|
            agent.name = ENV['AGENT_NAME'] || "remotedev"
          end
        end

        let!(:devfile_project) do
          Resource::Project.init do |project|
            project.add_name_uuid = false
            project.name = ENV['DEVFILE_PROJECT'] || "devfile-project"
          end
        end

        before do
          Flow::Login.sign_in
        end

        it_behaves_like 'workspaces actions'
      end
    end
  end
end
