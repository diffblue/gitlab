# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Runners::StaleGroupRunnersPruneService, feature_category: :runner_fleet do
  let(:service) { described_class.new }

  subject(:execute) { service.execute(NamespaceCiCdSetting.allowing_stale_runner_pruning.select(:namespace_id)) }

  shared_context 'with some stale group runners on group1' do
    let!(:active_runner) do
      create(:ci_runner, :group, groups: [group1], created_at: 5.months.ago, contacted_at: 10.seconds.ago)
    end

    let!(:stale_runners) do
      create_list(:ci_runner, 3, :group, groups: [group1], created_at: 5.months.ago, contacted_at: 4.months.ago)
    end

    let(:group2) { create(:group) }

    before do
      stub_const("#{described_class}::GROUP_BATCH_SIZE", 1)

      group1.ci_cd_settings.update!(allow_stale_runner_pruning: true)
      group2.ci_cd_settings.update!(allow_stale_runner_pruning: true)
    end
  end

  shared_examples 'perform on empty groups relation does not prune any runners' do
    context 'with empty groups relation' do
      let!(:stale_runner) do
        create(:ci_runner, :group, groups: [group1], created_at: 5.months.ago, contacted_at: 4.months.ago)
      end

      it 'does not prune any runners and returns :success status' do
        expect(service).not_to receive(:delete_stale_group_runners_in_batches)

        expect do
          expect(execute).to be_success
          expect(execute.payload).to match({ total_pruned: 0 })
        end.not_to change { Ci::Runner.count }.from(1)
      end
    end
  end

  shared_examples 'pruning is executed on stale runners' do
    it 'prunes all runners in batches' do
      expect do
        expect(execute).to be_success
        expect(execute.payload).to match({ total_pruned: 3 })
      end.to change { Ci::Runner.count }.from(4).to(1)
    end
  end

  shared_examples 'pruning is not executed on stale runners' do
    it 'does not prune any runners' do
      expect do
        expect(execute).to be_success
        expect(execute.payload).to match({ total_pruned: 0 })
      end.not_to change { Ci::Runner.count }
    end
  end

  context 'on self-managed instance', :freeze_time do
    let!(:group1) { create(:group) }

    before do
      stub_application_setting(check_namespace_plan: false)
    end

    it_behaves_like 'perform on empty groups relation does not prune any runners'

    context 'when stale_runner_cleanup_for_namespace licensed feature is available' do
      before do
        stub_licensed_features(stale_runner_cleanup_for_namespace: true)
      end

      context 'with some stale group runners on group1' do
        include_context 'with some stale group runners on group1'

        it_behaves_like 'pruning is executed on stale runners'
      end
    end

    context 'when stale_runner_cleanup_for_namespace licensed feature is unavailable' do
      before do
        stub_licensed_features(stale_runner_cleanup_for_namespace: false)
      end

      context 'with some stale group runners on group1' do
        include_context 'with some stale group runners on group1'

        it_behaves_like 'pruning is not executed on stale runners'
      end
    end
  end

  context 'on .com', :saas, :freeze_time do
    let(:namespace_plan) { :ultimate_plan }
    let!(:group1) { create(:group_with_plan, plan: namespace_plan) }

    before do
      stub_application_setting(check_namespace_plan: true)
      stub_licensed_features(stale_runner_cleanup_for_namespace: true)
    end

    it_behaves_like 'perform on empty groups relation does not prune any runners'

    context 'with some stale group runners on group1' do
      include_context 'with some stale group runners on group1'

      it_behaves_like 'pruning is executed on stale runners'

      context 'with premium plan' do
        let(:namespace_plan) { :premium_plan }

        it_behaves_like 'pruning is not executed on stale runners'
      end
    end
  end
end
