# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Minutes::CostFactor do
  using RSpec::Parameterized::TableSyntax

  let(:runner_type) {}
  let(:public_cost_factor) {}
  let(:private_cost_factor) {}
  let(:cost_factor) { described_class.new(runner.runner_matcher) }

  let(:runner) do
    build_stubbed(:ci_runner,
      runner_type,
      public_projects_minutes_cost_factor: public_cost_factor,
      private_projects_minutes_cost_factor: private_cost_factor
    )
  end

  describe '.new' do
    let(:runner) { build_stubbed(:ci_runner) }

    it 'raises errors when initialized with a runner object' do
      expect { described_class.new(runner) }.to raise_error(ArgumentError)
    end
  end

  describe '#enabled?' do
    let(:project) { build_stubbed(:project) }

    subject(:is_enabled) { cost_factor.enabled?(project) }

    context 'when the cost factor is zero' do
      before do
        expect(cost_factor).to receive(:for_project).with(project) { 0 }
      end

      it { is_expected.to be_falsey }
    end

    context 'when the cost factor is positive' do
      before do
        expect(cost_factor).to receive(:for_project).with(project) { 0.5 }
      end

      it { is_expected.to be_truthy }
    end
  end

  describe '#disabled?' do
    let(:project) { build_stubbed(:project) }

    subject(:is_disabled) { cost_factor.disabled?(project) }

    context 'when the cost factor is zero' do
      before do
        expect(cost_factor).to receive(:for_project).with(project) { 0 }
      end

      it { is_expected.to be_truthy }
    end

    context 'when the cost factor is positive' do
      before do
        expect(cost_factor).to receive(:for_project).with(project) { 0.5 }
      end

      it { is_expected.to be_falsey }
    end
  end

  describe '#for_project', :saas do
    subject(:for_project) { cost_factor.for_project(project) }

    where(:runner_type, :visibility_level, :public_cost_factor, :private_cost_factor, :namespace_limit, :instance_limit, :result) do
      :project  | Gitlab::VisibilityLevel::PRIVATE  | 1 | 1 | nil | 400 | 0
      :project  | Gitlab::VisibilityLevel::INTERNAL | 1 | 1 | nil | 400 | 0
      :project  | Gitlab::VisibilityLevel::PUBLIC   | 1 | 1 | nil | 400 | 0
      :project  | Gitlab::VisibilityLevel::PUBLIC   | 1 | 1 | 0   | 0   | 0
      :project  | Gitlab::VisibilityLevel::PUBLIC   | 1 | 1 | nil | nil | 0

      :group    | Gitlab::VisibilityLevel::PRIVATE  | 1 | 1 | nil | 400 | 0
      :group    | Gitlab::VisibilityLevel::INTERNAL | 1 | 1 | nil | 400 | 0
      :group    | Gitlab::VisibilityLevel::PUBLIC   | 1 | 1 | nil | 400 | 0
      :group    | Gitlab::VisibilityLevel::PUBLIC   | 1 | 1 | 0   | 0   | 0
      :group    | Gitlab::VisibilityLevel::PUBLIC   | 1 | 1 | nil | nil | 0

      :instance | Gitlab::VisibilityLevel::PUBLIC   | 0 | 5 | nil | 400 | 0
      :instance | Gitlab::VisibilityLevel::PUBLIC   | 0 | 5 | nil | nil | 0
      :instance | Gitlab::VisibilityLevel::PUBLIC   | 0 | 5 | nil | 0   | 0
      :instance | Gitlab::VisibilityLevel::PUBLIC   | 0 | 5 | 0   | 400 | 0
      :instance | Gitlab::VisibilityLevel::PUBLIC   | 0 | 5 | 400 | 0   | 0
      :instance | Gitlab::VisibilityLevel::PUBLIC   | 2 | 5 | 400 | 0   | 2
      :instance | Gitlab::VisibilityLevel::PUBLIC   | 2 | 5 | nil | 400 | 2
      :instance | Gitlab::VisibilityLevel::PUBLIC   | 2 | 5 | nil | 0   | 0

      :instance | Gitlab::VisibilityLevel::INTERNAL | 0 | 5 | nil | 400 | 5
      :instance | Gitlab::VisibilityLevel::INTERNAL | 0 | 5 | nil | nil | 0
      :instance | Gitlab::VisibilityLevel::INTERNAL | 0 | 5 | nil | 0   | 0
      :instance | Gitlab::VisibilityLevel::INTERNAL | 0 | 5 | 0   | 400 | 0
      :instance | Gitlab::VisibilityLevel::INTERNAL | 0 | 5 | 400 | 0   | 5
      :instance | Gitlab::VisibilityLevel::INTERNAL | 0 | 0 | 400 | 0   | 0

      :instance | Gitlab::VisibilityLevel::PRIVATE  | 0 | 5 | nil | 400 | 5
      :instance | Gitlab::VisibilityLevel::PRIVATE  | 0 | 5 | nil | nil | 0
      :instance | Gitlab::VisibilityLevel::PRIVATE  | 0 | 5 | nil | 0   | 0
      :instance | Gitlab::VisibilityLevel::PRIVATE  | 0 | 5 | 0   | 400 | 0
      :instance | Gitlab::VisibilityLevel::PRIVATE  | 0 | 5 | 400 | 0   | 5
      :instance | Gitlab::VisibilityLevel::PRIVATE  | 0 | 0 | 400 | 0   | 0
    end

    with_them do
      let(:namespace) do
        create(:group, shared_runners_minutes_limit: namespace_limit)
      end

      let(:project) do
        create(:project, namespace: namespace, visibility_level: visibility_level)
      end

      before do
        allow(Gitlab::CurrentSettings).to receive(:shared_runners_minutes) { instance_limit }
      end

      it { is_expected.to eq(result) }
    end

    context 'when plan based cost factor', :saas do
      let(:runner_type) { :instance }
      let(:project) { create(:project, visibility_level: visibility_level) }
      let(:public_cost_factor) { 2 }
      let(:private_cost_factor) { 4 }

      before do
        create(:gitlab_subscription, namespace: project.namespace, hosted_plan: plan)
        allow(Gitlab::CurrentSettings).to receive(:shared_runners_minutes) { 100 }
      end

      context 'when project has an Open Source plan' do
        let(:plan) { create(:opensource_plan) }

        context 'when the project is private' do
          let(:visibility_level) { Gitlab::VisibilityLevel::PRIVATE }

          it 'returns the runner private cost factor' do
            expect(subject).to eq(private_cost_factor)
          end
        end

        context 'when the project is public' do
          let(:visibility_level) { Gitlab::VisibilityLevel::PUBLIC }

          context 'when the public open source cost factor is lower' do
            specify { expect(subject).to eq(described_class::PUBLIC_OPEN_SOURCE_PLAN) }
          end

          context 'when the runner cost factor is lower' do
            let(:public_cost_factor) { described_class::PUBLIC_OPEN_SOURCE_PLAN - 0.001 }

            specify { expect(subject).to eq(public_cost_factor) }
          end
        end
      end

      context 'when project does not have an Open Source plan' do
        let(:plan) { create(:free_plan) }

        context 'when the project is private' do
          let(:visibility_level) { Gitlab::VisibilityLevel::PRIVATE }

          it 'returns the private cost factor' do
            expect(subject).to eq(private_cost_factor)
          end
        end

        context 'when the project is public' do
          let(:visibility_level) { Gitlab::VisibilityLevel::PUBLIC }

          it 'returns the runner public cost factor' do
            expect(subject).to eq(public_cost_factor)
          end
        end
      end
    end

    context 'when project is forked' do
      let(:runner_type) { :instance }
      let(:project) { create(:project, visibility_level: visibility_level) }
      let(:public_cost_factor) { 2 }
      let(:private_cost_factor) { 4 }
      let(:fork_source_project) { create(:project, visibility_level: source_visibility_level) }

      before do
        allow(project).to receive(:fork_source).and_return(fork_source_project)
        allow(Gitlab::CurrentSettings).to receive(:shared_runners_minutes) { 100 }
      end

      context 'when the project is public' do
        let(:visibility_level) { Gitlab::VisibilityLevel::PUBLIC }

        context 'when the fork_source project is private' do
          let(:source_visibility_level) { Gitlab::VisibilityLevel::PRIVATE }

          it 'returns the runner public cost factor' do
            expect(subject).to eq(public_cost_factor)
          end
        end

        context 'when the fork_source project is public' do
          let(:source_visibility_level) { Gitlab::VisibilityLevel::PUBLIC }

          context 'when the forked source cost factor is lower' do
            context 'when the plan is open source' do
              before do
                create(:gitlab_subscription, namespace: project.fork_source.namespace, hosted_plan: create(:opensource_plan))
              end

              specify { expect(subject).to eq(described_class::OPEN_SOURCE_CONTRIBUTION) }
            end

            context 'when the plan is not open source' do
              specify { expect(subject).to eq(public_cost_factor) }
            end
          end

          context 'when the runner cost factor is lower' do
            let(:public_cost_factor) { described_class::OPEN_SOURCE_CONTRIBUTION - 0.001 }

            specify { expect(subject).to eq(public_cost_factor) }
          end
        end
      end

      context 'when the project is private' do
        let(:visibility_level) { Gitlab::VisibilityLevel::PRIVATE }
        let(:source_visibility_level) { Gitlab::VisibilityLevel::PUBLIC }

        specify { expect(subject).to eq(private_cost_factor) }
      end
    end
  end
end
