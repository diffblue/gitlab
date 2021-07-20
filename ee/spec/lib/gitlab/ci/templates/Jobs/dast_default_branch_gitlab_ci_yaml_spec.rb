# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Jobs/DAST-Default-Branch-Deploy.gitlab-ci.yml' do
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

  describe 'the created pipeline' do
    let_it_be(:project) do
      create(:project, :repository, variables: [
        build(:ci_variable, key: 'CI_KUBERNETES_ACTIVE', value: 'true')
      ])
    end

    let(:user) { project.owner }
    let(:default_branch) { 'master' }
    let(:pipeline_ref) { default_branch }
    let(:service) { Ci::CreatePipelineService.new(project, user, ref: pipeline_ref) }
    let(:pipeline) { service.execute!(:push).payload }
    let(:build_names) { pipeline.builds.pluck(:name) }

    before do
      stub_ci_pipeline_yaml_file(template)
      allow_next_instance_of(Ci::BuildScheduleWorker) do |worker|
        allow(worker).to receive(:perform).and_return(true)
      end
      allow(project).to receive(:default_branch).and_return(default_branch)
    end

    it 'has no errors' do
      expect(pipeline.errors).to be_empty
    end

    context 'when project has no license' do
      it 'includes no DAST jobs' do
        expect(build_names).to match_array(%w(placeholder))
      end
    end

    context 'when project has Ultimate license' do
      let(:license) { build(:license, plan: License::ULTIMATE_PLAN) }

      before do
        allow(License).to receive(:current).and_return(license)
      end

      context 'default branch' do
        it 'includes the DAST environment jobs by default' do
          expect(build_names).to include('dast_environment_deploy')
          expect(build_names).to include('stop_dast_environment')
        end

        it 'always runs the cleanup job' do
          expect(pipeline.builds.find_by(name: 'stop_dast_environment').when).to eq('always')
        end

        it 'does not include the DAST environment jobs when DAST_DISABLED' do
          create(:ci_variable, project: project, key: 'DAST_DISABLED', value: '1')

          expect(build_names).not_to include('dast_environment_deploy')
          expect(build_names).not_to include('stop_dast_environment')
        end
      end

      context 'on another branch' do
        let(:pipeline_ref) { 'feature' }

        it 'does not include DAST environment jobs' do
          expect(build_names).not_to include('dast_environment_deploy')
          expect(build_names).not_to include('stop_dast_environment')
        end
      end
    end
  end
end
