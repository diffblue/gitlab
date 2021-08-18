# frozen_string_literal: true

module QA
  RSpec.describe 'Protect' do
    describe 'Threat Monitoring Policy List page' do
      let!(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = Runtime::Env.auto_devops_project_name || 'project-with-protect'
          project.description = 'Project with Protect'
          project.auto_devops_enabled = true
          project.initialize_with_readme = true
          project.template_name = 'express'
        end
      end

      after do
        project.remove_via_api!
      end

      context 'without k8s cluster' do
        before do
          Flow::Login.sign_in
          project.visit!
        end

        it 'can load Threat Monitoring page and view the policy alert list', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/quality/test_cases/1892' do
          Page::Project::Menu.perform(&:click_on_threat_monitoring)

          EE::Page::Project::ThreatMonitoring::AlertsList.perform do |alerts_list|
            aggregate_failures do
              expect(alerts_list).to have_alerts_tab
              expect(alerts_list).to have_alerts_list
            end
          end
        end
      end

      context 'with k8s cluster', :require_admin, :kubernetes, :orchestrated, :runner, quarantine: { issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/335202', type: :broken } do
        let(:policy_name) { 'l3-rule' }
        let!(:cluster) { Service::KubernetesCluster.new(provider_class: Service::ClusterProvider::K3sCilium).create! }
        let!(:runner) do
          Resource::Runner.fabricate_via_api! do |resource|
            resource.project = project
            resource.executor = :docker
          end
        end

        let(:optional_jobs) do
          %w[
            LICENSE_MANAGEMENT_DISABLED
            SAST_DISABLED DAST_DISABLED
            DEPENDENCY_SCANNING_DISABLED
            CONTAINER_SCANNING_DISABLED
            CODE_QUALITY_DISABLED
          ]
        end

        before do
          Flow::Login.sign_in_as_admin
        end

        after do
          runner.remove_via_api!
          cluster.remove!
        end

        it 'loads a sample network policy under policies tab on the Threat Monitoring page', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/quality/test_cases/1925' do
          Resource::KubernetesCluster::ProjectCluster.fabricate_via_browser_ui! do |k8s_cluster|
            k8s_cluster.project = project
            k8s_cluster.cluster = cluster
            k8s_cluster.install_ingress = true
          end.project.visit!

          Resource::Pipeline.fabricate_via_api! do |pipeline|
            pipeline.project = project
            pipeline.variables =
              optional_jobs.map do |job|
                { key: job, value: '1', variable_type: 'env_var' }
              end
          end

          Page::Project::Menu.perform(&:click_ci_cd_pipelines)

          Page::Project::Pipeline::Index.perform do |index|
            index.wait_for_latest_pipeline_completed
          end

          cluster.add_sample_policy(project, policy_name: policy_name)

          Page::Project::Menu.perform(&:click_on_threat_monitoring)
          EE::Page::Project::ThreatMonitoring::Index.perform do |index|
            index.click_policies_tab
            aggregate_failures do
              expect(index).to have_policies_tab
              expect(index.has_content?(policy_name)).to be true
            end
          end
        end
      end
    end
  end
end
