# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::ProcessPipelineService, '#execute', feature_category: :continuous_integration do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:downstream) { create(:project, :repository) }

  let_it_be(:pipeline) do
    create(:ci_empty_pipeline, ref: 'master', project: project, user: user)
  end

  let_it_be(:build_stage) { create(:ci_stage, name: 'build', pipeline: pipeline, position: 0) }
  let_it_be(:test_stage) { create(:ci_stage, name: 'test', pipeline: pipeline, position: 1) }
  let_it_be(:deploy_stage) { create(:ci_stage, name: 'deploy', pipeline: pipeline, position: 2) }

  let(:service) { described_class.new(pipeline) }

  before do
    project.add_maintainer(user)
    downstream.add_developer(user)
  end

  describe 'cross-project pipelines' do
    before do
      create_processable(:build, name: 'build', ci_stage: build_stage, stage_idx: build_stage.position)
      create_processable(
        :bridge, :variables, name: 'cross', ci_stage: test_stage, downstream: downstream, stage_idx: test_stage.position
      )
      create_processable(:build, name: 'deploy', ci_stage: deploy_stage, stage_idx: deploy_stage.position)

      stub_ci_pipeline_to_return_yaml_file
    end

    it 'creates a downstream cross-project pipeline' do
      service.execute
      Sidekiq::Worker.drain_all

      expect_statuses(%w[build pending], %w[cross created], %w[deploy created])

      update_build_status(:build, :success)
      Sidekiq::Worker.drain_all

      expect_statuses(%w[build success], %w[cross success], %w[deploy pending])

      expect(downstream.ci_pipelines).to be_one
      expect(downstream.ci_pipelines.first).to be_pending
      expect(downstream.builds).not_to be_empty
      expect(downstream.builds.first.variables)
        .to include(key: 'BRIDGE', value: 'cross', public: false, masked: false)
    end
  end

  def expect_statuses(*expected)
    statuses = pipeline.statuses
      .where(name: expected.map(&:first))
      .pluck(:name, :status)

    expect(statuses).to contain_exactly(*expected)
  end

  def update_build_status(name, status)
    pipeline.builds.find_by(name: name).public_send(status)
  end

  def create_processable(type, *traits, **opts)
    create(
      "ci_#{type}",
      *traits,
      status: :created,
      pipeline: pipeline,
      user: user,
      **opts
    )
  end
end
