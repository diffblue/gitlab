# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Jobs/DAST-Default-Branch-Deploy.gitlab-ci.yml' do
  include Ci::TemplateHelpers

  subject(:template) do
    <<~YAML
      stages:
        - review
        - dast
        - cleanup

      include:
        - template: 'Jobs/DAST-Default-Branch-Deploy.gitlab-ci.yml'
        - template: 'Security/DAST.gitlab-ci.yml'

      placeholder:
        stage: review
        script:
          - keep pipeline validator happy by having a job when stages are intentionally empty
    YAML
  end

  describe 'DAST_AUTO_DEPLOY_IMAGE_VERSION' do
    it 'corresponds to a published image in the registry' do
      template = Gitlab::Template::GitlabCiYmlTemplate.find('Jobs/DAST-Default-Branch-Deploy')
      registry = "https://#{template_registry_host}"
      repository = "gitlab-org/cluster-integration/auto-deploy-image"
      reference = YAML.safe_load(template.content, aliases: true).dig('variables', 'DAST_AUTO_DEPLOY_IMAGE_VERSION')

      expect(public_image_exist?(registry, repository, reference)).to be true
    end
  end

  describe 'the created pipeline' do
    let(:user) { project.first_owner }
    let(:default_branch) { 'master' }
    let(:pipeline_ref) { default_branch }
    let(:service) { Ci::CreatePipelineService.new(project, user, ref: pipeline_ref) }
    let(:pipeline) { service.execute(:push).payload }
    let(:build_names) { pipeline.builds.pluck(:name) }
    let(:other_jobs) { %w(dast placeholder) }
    let(:dast_environment_jobs) do
      %w(dast_environment_deploy stop_dast_environment dast_ecs_environment_deploy stop_dast_ecs_environment)
    end

    before do
      stub_ci_pipeline_yaml_file(template)
      allow_next_instance_of(Ci::BuildScheduleWorker) do |worker|
        allow(worker).to receive(:perform).and_return(true)
      end
      allow(project).to receive(:default_branch).and_return(default_branch)
    end

    shared_examples_for 'no DAST environment jobs' do
      it 'does not include DAST environment jobs' do
        expect(build_names).not_to include(*dast_environment_jobs)
      end
    end

    shared_examples_for 'no pipeline errors' do
      it 'has no errors' do
        expect(pipeline.errors).to be_empty
      end
    end

    shared_examples_for 'DAST environment jobs disabled by CI variable' do
      context 'when DAST_DISABLED is set' do
        before do
          create(:ci_variable, project: project, key: 'DAST_DISABLED', value: '1')
        end

        include_examples 'no DAST environment jobs'
      end

      context 'when DAST_DISABLED_FOR_DEFAULT_BRANCH is set' do
        before do
          create(:ci_variable, project: project, key: 'DAST_DISABLED_FOR_DEFAULT_BRANCH', value: '1')
        end

        include_examples 'no DAST environment jobs'
      end

      context 'when DAST_WEBSITE is set' do
        before do
          create(:ci_variable, project: project, key: 'DAST_WEBSITE', value: 'http://foo.com')
        end

        include_examples 'no DAST environment jobs'
      end
    end

    context 'when deploying to kubernetes' do
      let(:project) { project_with_ci_kubernetes_active }

      let_it_be_with_refind(:project_with_ci_kubernetes_active) do
        create(:project, :repository, variables: [
                 build(:ci_variable, key: 'CI_KUBERNETES_ACTIVE', value: 'true')
               ])
      end

      include_examples 'no pipeline errors'

      context 'when project has no license' do
        include_examples 'no DAST environment jobs'
      end

      context 'when project has Ultimate license' do
        let(:license) { build(:license, plan: License::ULTIMATE_PLAN) }

        before do
          allow(License).to receive(:current).and_return(license)
        end

        context 'default branch' do
          it 'includes the DAST environment jobs by default', :aggregate_failures do
            expect(build_names).to contain_exactly(*other_jobs, 'dast_environment_deploy', 'stop_dast_environment')
            expect(pipeline.builds.find_by(name: 'stop_dast_environment').when).to eq('always')
          end

          include_examples 'DAST environment jobs disabled by CI variable'

          context 'when KUBECONFIG and not CI_KUBERNETES_ACTIVE' do
            let(:project) do
              create(:project, :repository, variables: [
                       build(:ci_variable, key: 'KUBECONFIG', value: 'true')
                     ])
            end

            it 'includes the DAST environment jobs', :aggregate_failures do
              expect(build_names).to contain_exactly(*other_jobs, 'dast_environment_deploy', 'stop_dast_environment')
              expect(pipeline.builds.find_by(name: 'stop_dast_environment').when).to eq('always')
            end
          end
        end

        context 'on another branch' do
          let(:pipeline_ref) { 'feature' }

          include_examples 'no DAST environment jobs'
        end
      end
    end

    context 'when deploying to ECS' do
      let(:project) { project_with_ci_ecs_active }

      let_it_be_with_refind(:project_with_ci_ecs_active) do
        create(:project, :repository, variables: [
                 build(:ci_variable, key: 'AUTO_DEVOPS_PLATFORM_TARGET', value: 'ECS')
               ])
      end

      include_examples 'no pipeline errors'

      context 'when project has no license' do
        include_examples 'no DAST environment jobs'
      end

      context 'when project has Ultimate license' do
        let(:license) { build(:license, plan: License::ULTIMATE_PLAN) }

        before do
          allow(License).to receive(:current).and_return(license)
        end

        context 'default branch' do
          it 'includes the DAST environment jobs by default', :aggregate_failures do
            expect(build_names).to contain_exactly(*other_jobs,
                                                   'dast_ecs_environment_deploy',
                                                   'stop_dast_ecs_environment')
            expect(pipeline.builds.find_by(name: 'stop_dast_ecs_environment').when).to eq('always')
          end

          include_examples 'DAST environment jobs disabled by CI variable'
        end

        context 'on another branch' do
          let(:pipeline_ref) { 'feature' }

          include_examples 'no DAST environment jobs'
        end
      end
    end

    context 'when deploying to other infrastructure' do
      let_it_be_with_refind(:project_with_other_infra) { create(:project, :repository) }

      let(:project) { project_with_other_infra }

      include_examples 'no pipeline errors'

      context 'when project has Ultimate license' do
        let(:license) { build(:license, plan: License::ULTIMATE_PLAN) }

        before do
          allow(License).to receive(:current).and_return(license)
        end

        context 'default branch' do
          include_examples 'no DAST environment jobs'
        end
      end
    end
  end
end
