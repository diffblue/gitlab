# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issues::RescheduleStuckIssueRebalancesWorker, :clean_gitlab_redis_shared_state do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }

  subject(:worker) { described_class.new }

  describe '#perform' do
    it 'does not schedule a rebalance' do
      expect(IssueRebalancingWorker).not_to receive(:perform_async)

      worker.perform
    end

    it 'schedules a rebalance in case there are any rebalances started' do
      Gitlab::Redis::SharedState.with do |redis|
        redis.sadd(::Gitlab::Issues::Rebalancing::State::CONCURRENT_RUNNING_REBALANCES_KEY, "#{::Gitlab::Issues::Rebalancing::State::NAMESPACE}/#{group.id}")
        redis.sadd(::Gitlab::Issues::Rebalancing::State::CONCURRENT_RUNNING_REBALANCES_KEY, "#{::Gitlab::Issues::Rebalancing::State::PROJECT}/#{project.id}")
      end

      expect(IssueRebalancingWorker).to receive(:bulk_perform_async).with([[nil, nil, group.id]]).once
      expect(IssueRebalancingWorker).to receive(:bulk_perform_async).with([[nil, project.id, nil]]).once

      worker.perform
    end
  end
end
