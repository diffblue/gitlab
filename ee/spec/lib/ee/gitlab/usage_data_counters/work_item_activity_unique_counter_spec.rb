# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataCounters::WorkItemActivityUniqueCounter, :clean_gitlab_redis_shared_state do
  let(:user) { build(:user, id: 1) }

  describe '.track_work_item_weight_changed_action' do
    subject(:track_event) { described_class.track_work_item_weight_changed_action(author: user) }

    let(:event_name) { described_class::WORK_ITEM_WEIGHT_CHANGED }

    it_behaves_like 'work item unique counter'
  end

  describe '.track_work_item_iteration_changed_action' do
    subject(:track_event) { described_class.track_work_item_iteration_changed_action(author: user) }

    let(:event_name) { described_class::WORK_ITEM_ITERATION_CHANGED }

    it_behaves_like 'work item unique counter'
  end
end
