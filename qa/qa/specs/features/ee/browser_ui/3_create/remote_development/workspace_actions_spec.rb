# frozen_string_literal: true

module QA
  RSpec.describe 'Create', only: { subdomain: %i[staging] }, product_group: :ide do
    describe 'Remote Development' do
      include Runtime::Fixtures

      context 'when prerequisite is done in runtime',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/419248' do
        let!(:cluster) do
          if QA::Runtime::Env.workspaces_cluster_available?
            Service::KubernetesCluster.new(provider_class: Service::ClusterProvider::Gcloud).connect!
          else
            Service::KubernetesCluster.new(provider_class: Service::ClusterProvider::Gcloud).create!
          end
        end

        let(:parent_group) do
          QA::Resource::Group.fabricate_via_api! do |group|
            group.path = "parent-group-to-test-remote-development-#{SecureRandom.hex(8)}"
          end
        end

        let(:agent_project) do
          Resource::Project.fabricate_via_api! do |project|
            project.group = parent_group
            project.name = "agent-project"
          end
        end

        let(:kubernetes_agent) do
          Resource::Clusters::Agent.fabricate_via_api! do |agent|
            agent.name = "remotedev-#{SecureRandom.hex(4)}"
            agent.project = agent_project
          end
        end

        let!(:agent_token) do
          Resource::Clusters::AgentToken.fabricate_via_api! do |token|
            token.agent = kubernetes_agent
          end
        end

        let!(:agent_config_file) do
          Resource::Repository::Commit.fabricate_via_api! do |commit|
            agent_config_yaml = ERB.new(read_ee_fixture('remote_development', 'agent-config.yaml.erb')).result(binding)

            commit.project = agent_project
            commit.commit_message = 'Add remote dev agent configuration'
            commit.add_files([{ file_path: ".gitlab/agents/#{kubernetes_agent.name}/config.yaml",
                                content: agent_config_yaml }])
          end
        end

        let(:devfile_project) do
          Resource::Project.fabricate_via_api! do |project|
            project.group = parent_group
            project.name = "devfile-project"
          end
        end

        let!(:devfile_file) do
          Resource::Repository::Commit.fabricate_via_api! do |commit|
            devfile_yaml = ERB.new(read_ee_fixture('remote_development', 'devfile.yaml.erb')).result(binding)

            commit.project = devfile_project
            commit.commit_message = 'Add .devfile.yaml'
            commit.add_files([{ file_path: '.devfile.yaml', content: devfile_yaml }])
          end
        end

        before do
          cluster.setup_workspaces_in_cluster unless QA::Runtime::Env.workspaces_cluster_available?
          cluster.install_kubernetes_agent(agent_token.token, kubernetes_agent.name)
          cluster.update_dns_with_load_balancer_ip
          Flow::Login.sign_in
        end

        after do
          if QA::Runtime::Env.workspaces_cluster_available?
            cluster.uninstall_kubernetes_agent(kubernetes_agent.name)
          else
            cluster&.remove!
          end

          agent_token.remove_via_api!
          kubernetes_agent.remove_via_api!
          parent_group.remove_via_api!
        end

        it_behaves_like 'workspaces actions'
      end
    end
  end
end
