# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Secret-Detection.gitlab-ci.yml', feature_category: :continuous_integration do
  subject(:template) do
    <<~YAML
      include:
        - template: 'Jobs/Secret-Detection.latest.gitlab-ci.yml'
    YAML
  end

  describe 'the created pipeline' do
    let(:default_branch) { 'master' }
    let(:files) { { 'README.md' => '' } }
    let(:project) { create(:project, :custom_repo, files: files) }
    let(:user) { project.first_owner }
    let(:service) { Ci::CreatePipelineService.new(project, user, ref: 'master') }
    let(:pipeline) { service.execute(:push).payload }
    let(:build_names) { pipeline.builds.pluck(:name) }

    before do
      stub_ci_pipeline_yaml_file(template)
      allow_next_instance_of(Ci::BuildScheduleWorker) do |worker|
        allow(worker).to receive(:perform).and_return(true)
      end
      allow(project).to receive(:default_branch).and_return(default_branch)
    end

    context 'when project has no license' do
      context 'when SECRET_DETECTION_DISABLED="1"' do
        before do
          create(:ci_variable, project: project, key: 'SECRET_DETECTION_DISABLED', value: '1')
        end

        it 'includes no jobs' do
          expect(build_names).to be_empty
          expect(pipeline.errors.full_messages).to match_array(['Pipeline will not run for the selected trigger. ' \
            'The rules configuration prevented any jobs from being added to the pipeline.'])
        end
      end

      context 'when SECRET_DETECTION_DISABLED="true"' do
        before do
          create(:ci_variable, project: project, key: 'SECRET_DETECTION_DISABLED', value: 'true')
        end

        it 'includes no jobs' do
          expect(build_names).to be_empty
          expect(pipeline.errors.full_messages).to match_array(['Pipeline will not run for the selected trigger. ' \
            'The rules configuration prevented any jobs from being added to the pipeline.'])
        end
      end

      context 'when SECRET_DETECTION_DISABLED="false"' do
        before do
          create(:ci_variable, project: project, key: 'SECRET_DETECTION_DISABLED', value: 'false')
        end

        it 'includes jobs' do
          expect(build_names).not_to be_empty
        end
      end

      context 'when branch pipeline' do
        it 'creates a pipeline with the expected jobs' do
          expect(pipeline.errors.full_messages).to be_empty
          expect(build_names).to match_array(%w(secret_detection))
        end
      end

      context 'when MR pipeline' do
        let(:service) { MergeRequests::CreatePipelineService.new(project: project, current_user: user) }
        let(:feature_branch) { 'feature' }
        let(:pipeline) { service.execute(merge_request).payload }

        let(:merge_request) do
          create(:merge_request,
            source_project: project,
            source_branch: feature_branch,
            target_project: project,
            target_branch: default_branch)
        end

        before do
          project.repository.create_file(
            project.creator,
            'README.md',
            "README on branch feature",
            message: 'Add README.md',
            branch_name: feature_branch)
        end

        it 'creates a pipeline with the expected jobs' do
          expect(pipeline).to be_merge_request_event
          expect(pipeline.errors.full_messages).to be_empty
          expect(build_names).to match_array(%w(secret_detection))
        end
      end
    end
  end
end
