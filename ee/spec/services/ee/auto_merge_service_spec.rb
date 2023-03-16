# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AutoMergeService, feature_category: :code_review_workflow do
  describe '.all_strategies_ordered_by_preference' do
    subject { described_class.all_strategies_ordered_by_preference }

    it 'returns all strategies in preference order' do
      is_expected.to eq([AutoMergeService::STRATEGY_MERGE_TRAIN,
                         AutoMergeService::STRATEGY_ADD_TO_MERGE_TRAIN_WHEN_PIPELINE_SUCCEEDS,
                         AutoMergeService::STRATEGY_MERGE_WHEN_PIPELINE_SUCCEEDS])
    end
  end
end
