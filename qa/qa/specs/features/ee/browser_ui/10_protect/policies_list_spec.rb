# frozen_string_literal: true

module QA
  RSpec.describe 'Protect' do
    describe 'Policies List page' do
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

        it 'can load Policies page and view the policies list', :smoke, testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/quality/test_cases/2382' do
          Page::Project::Menu.perform(&:click_on_policies)

          EE::Page::Project::Policies::Index.perform do |policies_page|
            aggregate_failures do
              expect(policies_page).to have_policies_list
            end
          end
        end

        it 'can navigate to Policy Editor page', :smoke, testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/quality/test_cases/2294' do
          Page::Project::Menu.perform(&:click_on_policies)

          EE::Page::Project::Policies::Index.perform(&:click_new_policy_button)

          EE::Page::Project::Policies::PolicyEditor.perform do |policy_editor|
            aggregate_failures do
              expect(policy_editor).to have_policy_type_form_select
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

        it 'loads a sample network policy under policies page', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/quality/test_cases/1925' do
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

          Page::Project::Menu.perform(&:click_on_policies)
          EE::Page::Project::Policies::Index.perform do |index|
            aggregate_failures do
              expect(policies_list).to have_policies_list
              expect(index.has_content?(policy_name)).to be true
            end
          end
        end
      end
    end
  end
end
