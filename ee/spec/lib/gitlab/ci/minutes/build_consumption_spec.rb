# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Minutes::BuildConsumption do
  using RSpec::Parameterized::TableSyntax

  let(:consumption) { described_class.new(build, build.duration) }
  let(:build) { build_stubbed(:ci_build, runner: runner, project: project) }

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
      before do
        runner.update!(
          public_projects_minutes_cost_factor: public_cost_factor,
          private_projects_minutes_cost_factor: private_cost_factor)

        project.update!(visibility_level: visibility_level)

        allow(build).to receive(:duration).and_return(duration)
        allow(::Gitlab::CurrentSettings).to receive(:shared_runners_minutes) { 400 }
      end

      it 'returns the expected consumption' do
        expect(subject).to eq(result)
      end
    end
  end
end
