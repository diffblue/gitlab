# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'SAST-IaC.latest.gitlab-ci.yml' do
  subject(:template) { Gitlab::Template::GitlabCiYmlTemplate.find('SAST-IaC.latest') }

  describe 'the created pipeline' do
    let(:default_branch) { 'master' }
    let(:files) { { 'README.md' => '' } }
    let(:project) { create(:project, :custom_repo, files: files) }
    let(:user) { project.first_owner }
    let(:service) { Ci::CreatePipelineService.new(project, user, ref: 'master') }
    let(:pipeline) { service.execute!(:push).payload }
    let(:build_names) { pipeline.builds.pluck(:name) }

    before do
      stub_ci_pipeline_yaml_file(template.content)
      allow_next_instance_of(Ci::BuildScheduleWorker) do |worker|
        allow(worker).to receive(:perform).and_return(true)
      end
      allow(project).to receive(:default_branch).and_return(default_branch)
    end

    context 'when project has no license' do
      context 'when SAST_DISABLED=1' do
        before do
          create(:ci_variable, project: project, key: 'SAST_DISABLED', value: '1')
        end

        it 'includes no jobs' do
          expect { pipeline }.to raise_error(Ci::CreatePipelineService::CreateError)
        end
      end
    end

    context 'by default' do
      it 'creates a pipeline with the expected jobs' do
        expect(build_names).to match_array(%w(kics-iac-sast))
      end
    end

    describe 'setting SECURE_ANALYZER_PREFIX' do
      it_behaves_like 'setting sec analyzer prefix dynamically', builds: %w(kics-iac-sast), namespace: 'sast'
    end
  end
end
