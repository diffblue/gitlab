# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Runners::StaleGroupRunnersPruneCronWorker do
  let(:worker) { described_class.new }

  describe '#perform' do
    let_it_be(:group1) { create(:group) }
    let_it_be(:group2) { create(:group) }

    let!(:runner1) do
      create(:ci_runner, :group, groups: [group1], created_at: 4.months.ago, contacted_at: 4.months.ago)
    end

    let!(:runner2) { create(:ci_runner, :group, groups: [group1]) }
    let!(:runner3) { create(:ci_runner, :group, groups: [group2]) }

    it 'delegates to Ci::Runners::StaleGroupRunnersPruneService' do
      group1.update!(allow_stale_runner_pruning: false)
      group2.update!(allow_stale_runner_pruning: true)

      expect_next_instance_of(Ci::Runners::StaleGroupRunnersPruneService) do |service|
        expect(service)
          .to receive(:perform)
          .with([group2.ci_cd_settings])
      end

      worker.perform
    end

    it_behaves_like 'an idempotent worker' do
      context 'prunes stale runners when group1 is set to allow pruning' do
        it 'prunes stale runners' do
          group1.update!(allow_stale_runner_pruning: true)
          group2.update!(allow_stale_runner_pruning: false)

          expect { subject }.to change { Ci::Runner.count }.from(3).to(2)

          expect(Ci::Runner.all).to match_array [runner2, runner3]
        end
      end

      context 'does not prune any runners when only group2 is set to allow pruning' do
        it 'does not prune runners' do
          group1.update!(allow_stale_runner_pruning: false)
          group2.update!(allow_stale_runner_pruning: true)

          expect { subject }.not_to change { Ci::Runner.count }

          expect(Ci::Runner.all).to match_array [runner1, runner2, runner3]
        end
      end
    end
  end
end
