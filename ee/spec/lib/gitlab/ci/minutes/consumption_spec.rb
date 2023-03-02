# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Minutes::Consumption, feature_category: :continuous_integration do
  using RSpec::Parameterized::TableSyntax

  let(:consumption) do
    described_class.new(pipeline: build.pipeline, duration: build.duration, runner_matcher: runner.runner_matcher)
  end

  let(:pipeline) { build_stubbed(:ci_pipeline, project: project) }
  let(:build) { build_stubbed(:ci_build, runner: runner, project: project, pipeline: pipeline) }

  let_it_be(:project) { create(:project) }
  let_it_be_with_refind(:runner) { create(:ci_runner, :instance) }

  describe '#amount' do
    subject { consumption.amount }

    where(:duration, :visibility_level, :public_cost_factor, :private_cost_factor, :result) do
      120 | Gitlab::VisibilityLevel::PRIVATE  | 1.0 | 2.0 | 4.0
      120 | Gitlab::VisibilityLevel::INTERNAL | 1.0 | 2.0 | 4.0
      120 | Gitlab::VisibilityLevel::INTERNAL | 1.0 | 1.5 | 3.0
      120 | Gitlab::VisibilityLevel::PUBLIC   | 2.0 | 1.0 | 4.0
      120 | Gitlab::VisibilityLevel::PUBLIC   | 1.0 | 1.0 | 2.0
      120 | Gitlab::VisibilityLevel::PUBLIC   | 0.5 | 1.0 | 1.0
      119 | Gitlab::VisibilityLevel::PUBLIC   | 0.5 | 1.0 | 0.99
    end

    with_them do
      let(:expected_cost_factor) do
        next public_cost_factor if visibility_level == Gitlab::VisibilityLevel::PUBLIC

        private_cost_factor
      end

      before do
        runner.update!(
          public_projects_minutes_cost_factor: public_cost_factor,
          private_projects_minutes_cost_factor: private_cost_factor)

        project.update!(visibility_level: visibility_level)

        allow(build).to receive(:duration).and_return(duration)
        allow(::Gitlab::CurrentSettings).to receive(:shared_runners_minutes).and_return(400)
      end

      it 'returns the expected consumption' do
        expect(subject).to eq(result)
      end

      it 'logs the cost factor' do
        expect(Gitlab::AppLogger).to receive(:info).with(
          hash_including(
            cost_factor: expected_cost_factor,
            project_path: project.full_path,
            pipeline_id: build.pipeline_id,
            gitlab_cost_factor_applied: false
          )
        )

        subject
      end

      context 'when consumption comes from a GitLab contribution' do
        let(:contribution_cost_factor) do
          instance_double(::Gitlab::Ci::Minutes::GitlabContributionCostFactor, cost_factor: 0.25)
        end

        before do
          allow(::Gitlab::Ci::Minutes::GitlabContributionCostFactor)
            .to receive(:new)
            .with(build.project, build.merge_request)
            .and_return(contribution_cost_factor)
        end

        it 'returns the consumption using the contribution cost factor' do
          expected_consumption = (duration.to_f / 60 * 0.25).round(2)
          expect(subject).to eq(expected_consumption)
        end

        it 'logs that the contributor cost factor was granted' do
          expect(Gitlab::AppLogger).to receive(:info).with(
            hash_including(
              cost_factor: 0.25,
              project_path: project.full_path,
              pipeline_id: build.pipeline_id,
              gitlab_cost_factor_applied: true
            )
          )

          subject
        end
      end
    end
  end
end
