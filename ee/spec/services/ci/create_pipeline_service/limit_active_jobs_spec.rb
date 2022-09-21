# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Ci::CreatePipelineService, :yaml_processor_feature_flag_corectness do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { project.first_owner }
  let_it_be(:existing_pipeline) { create(:ci_pipeline, project: project) }
  let_it_be(:existing_builds) { create_list(:ci_build, 3, pipeline: existing_pipeline) }
  let_it_be(:existing_bridges) { create_list(:ci_bridge, 2, pipeline: existing_pipeline) }

  let(:service) { described_class.new(project, user, ref: 'refs/heads/master') }

  subject(:pipeline) { service.execute(:push).payload }

  before do
    stub_ci_pipeline_yaml_file(<<~YAML)
    job1:
      script: echo
    YAML
  end

  context 'when feature flag ci_limit_active_jobs_early is disabled' do
    before do
      stub_feature_flags(ci_limit_active_jobs_early: false)
    end

    context 'when project has exceeded the active jobs limit' do
      before do
        project.namespace.actual_limits.update!(ci_active_jobs: existing_builds.size)
      end

      it 'fails the pipeline after populating it' do
        expect(pipeline).to be_failed
        expect(pipeline).to be_job_activity_limit_exceeded
        expect(pipeline.statuses).not_to be_empty
      end
    end

    context 'when project has not exceeded the active jobs limit' do
      before do
        project.namespace.actual_limits.update!(ci_active_jobs: existing_builds.size + 10)
      end

      it 'creates the pipeline successfully' do
        expect(pipeline).to be_created
      end
    end
  end
end
