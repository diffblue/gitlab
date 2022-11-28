# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PendingBuild, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

  let(:build) { create(:ci_build, :created, pipeline: pipeline, project: project) }

  describe 'scopes' do
    describe '.with_ci_minutes_available' do
      subject(:pending_builds) { described_class.with_ci_minutes_available }

      context 'when pending builds does not have ci minutes available' do
        let!(:pending_build) { create(:ci_pending_build, minutes_exceeded: true) }

        it 'returns an empty collection of pending builds' do
          expect(pending_builds).to be_empty
        end
      end

      context 'when pending builds have ci minutes available' do
        let!(:pending_build) { create(:ci_pending_build, minutes_exceeded: false) }

        it 'returns matching pending builds' do
          expect(pending_builds).to contain_exactly(pending_build)
        end
      end
    end
  end

  describe '.upsert_from_build!' do
    shared_examples 'ci minutes not available' do
      it 'sets minutes_exceeded to true' do
        expect { described_class.upsert_from_build!(build) }.to change(Ci::PendingBuild, :count).by(1)

        expect(described_class.last.minutes_exceeded).to be_truthy
      end
    end

    shared_examples 'ci minutes available' do
      it 'sets minutes_exceeded to false' do
        expect { described_class.upsert_from_build!(build) }.to change(Ci::PendingBuild, :count).by(1)

        expect(described_class.last.minutes_exceeded).to be_falsey
      end
    end

    context 'when ci minutes are not available' do
      before do
        allow_next_instance_of(::Ci::Minutes::Usage) do |instance|
          allow(instance).to receive(:minutes_used_up?).and_return(true)
        end
      end

      context 'when project matches shared runners with cost factor enabled' do
        before do
          allow(::Ci::Runner).to receive(:any_shared_runners_with_enabled_cost_factor?).and_return(true)
        end

        it_behaves_like 'ci minutes not available'
      end

      context 'when project does not matches shared runners with cost factor enabled' do
        it_behaves_like 'ci minutes available'
      end
    end

    context 'when ci minutes are available' do
      it_behaves_like 'ci minutes available'
    end

    context 'when using shared runners with cost factor disabled' do
      context 'with new project' do
        it_behaves_like 'ci minutes available'
      end
    end
  end
end
