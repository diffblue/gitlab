# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Minutes::CostFactor do
  using RSpec::Parameterized::TableSyntax

  let(:runner_type) {}
  let(:public_cost_factor) {}
  let(:private_cost_factor) {}

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
    let(:cost_factor) { described_class.new(runner.runner_matcher) }

    subject { cost_factor.enabled?(project) }

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
    let(:cost_factor) { described_class.new(runner.runner_matcher) }

    subject { cost_factor.disabled?(project) }

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

  describe '#for_project' do
    context 'before the public project cost factor release date' do
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
        :instance | Gitlab::VisibilityLevel::PUBLIC   | 0 | 5 | nil | 0   | 0
        :instance | Gitlab::VisibilityLevel::PUBLIC   | 0 | 5 | nil | nil | 0
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
          create(:group, created_at: Date.new(2021, 7, 16), shared_runners_minutes_limit: namespace_limit)
        end

        let(:project) do
          create(:project, namespace: namespace, visibility_level: visibility_level)
        end

        before do
          allow(Gitlab::CurrentSettings).to receive(:shared_runners_minutes) { instance_limit }
        end

        subject { described_class.new(runner.runner_matcher).for_project(project) }

        it { is_expected.to eq(result) }
      end
    end

    context 'after the public project cost factor release date' do
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

        :instance | Gitlab::VisibilityLevel::PUBLIC   | 0 | 5 | nil | 400 | 0.008
        :instance | Gitlab::VisibilityLevel::PUBLIC   | 0 | 5 | nil | nil | 0
        :instance | Gitlab::VisibilityLevel::PUBLIC   | 0 | 5 | nil | 0   | 0
        :instance | Gitlab::VisibilityLevel::PUBLIC   | 0 | 5 | 0   | 400 | 0
        :instance | Gitlab::VisibilityLevel::PUBLIC   | 0 | 5 | 400 | 0   | 0.008
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
          create(:group, created_at: Date.new(2021, 7, 17), shared_runners_minutes_limit: namespace_limit)
        end

        let(:project) do
          create(:project, namespace: namespace, visibility_level: visibility_level)
        end

        before do
          allow(Gitlab::CurrentSettings).to receive(:shared_runners_minutes) { instance_limit }
          allow(Gitlab).to receive(:com?).and_return(true)
        end

        subject { described_class.new(runner.runner_matcher).for_project(project) }

        it { is_expected.to eq(result) }
      end
    end

    context 'when the project has an invalid visibility level' do
      let(:namespace) { nil }
      let(:private_cost_factor) { 1 }
      let(:public_cost_factor) { 1 }
      let(:runner_type) { :instance }
      let(:visibility_level) { 123 }

      it 'raises an error' do
        expect { subject }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#for_visibility' do
    subject { described_class.new(runner.runner_matcher).for_visibility(visibility_level) }

    where(:runner_type, :visibility_level, :public_cost_factor, :private_cost_factor, :result) do
      :project  | Gitlab::VisibilityLevel::PRIVATE  | 1 | 1 | 0
      :project  | Gitlab::VisibilityLevel::INTERNAL | 1 | 1 | 0
      :project  | Gitlab::VisibilityLevel::PUBLIC   | 1 | 1 | 0
      :group    | Gitlab::VisibilityLevel::PRIVATE  | 1 | 1 | 0
      :group    | Gitlab::VisibilityLevel::INTERNAL | 1 | 1 | 0
      :group    | Gitlab::VisibilityLevel::PUBLIC   | 1 | 1 | 0
      :instance | Gitlab::VisibilityLevel::PUBLIC   | 1 | 5 | 1
      :instance | Gitlab::VisibilityLevel::INTERNAL | 1 | 5 | 5
      :instance | Gitlab::VisibilityLevel::PRIVATE  | 1 | 5 | 5
    end

    with_them do
      it { is_expected.to eq(result) }
    end

    context 'with invalid visibility level' do
      let(:visibility_level) { 123 }
      let(:public_cost_factor) { 5 }
      let(:private_cost_factor) { 5 }
      let(:runner_type) { :instance }

      it 'raises an error' do
        expect { subject }.to raise_error(ArgumentError)
      end
    end
  end
end
