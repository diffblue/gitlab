# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Minutes::PipelineConsumption, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
  let(:runner_1) { create(:ci_runner, :instance) }
  let_it_be_with_reload(:runner_2) { create(:ci_runner, :instance) }
  let!(:build_1) { create(:ci_build, :success, runner: runner_1, pipeline: pipeline, project: project) }
  let!(:build_3) { create(:ci_build, :success, runner: runner_1, pipeline: pipeline, project: project) }
  let_it_be(:build_2) { create(:ci_build, :success, runner: runner_2, pipeline: pipeline, project: project) }

  subject { described_class.new(pipeline).amount }

  describe '#amount' do
    before do
      runner_1.update!(private_projects_minutes_cost_factor: 10)
      runner_2.update!(private_projects_minutes_cost_factor: 6)

      project.update!(visibility_level: Gitlab::VisibilityLevel::INTERNAL)
      allow(::Gitlab::CurrentSettings).to receive(:shared_runners_minutes).and_return(400)
    end

    it 'calculates minutes consumed correctly' do
      # (Build 1 and 3) 240/60 * 10 + (Build 2) 120/60 * 6
      expect(subject).to eq(52)
    end

    it 'filters out non-completed builds' do
      build_2.update!(status: 'pending')

      expect(subject).to eq(40)
    end

    context 'with private runners' do
      let(:runner_1) { create(:ci_runner, :project, projects: [project]) }

      it 'excludes non-instance runners' do
        expect(subject).to eq(12)
      end
    end
  end
end
