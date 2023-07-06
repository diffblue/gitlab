# frozen_string_literal: true

module EE
  module AutoMergeService
    extend ActiveSupport::Concern

    STRATEGY_MERGE_TRAIN = 'merge_train'
    STRATEGY_ADD_TO_MERGE_TRAIN_WHEN_PIPELINE_SUCCEEDS = 'add_to_merge_train_when_pipeline_succeeds'
    STRATEGY_MERGE_WHEN_CHECKS_PASS = 'merge_when_checks_pass'
    EE_STRATEGIES = [STRATEGY_MERGE_TRAIN, STRATEGY_ADD_TO_MERGE_TRAIN_WHEN_PIPELINE_SUCCEEDS].freeze

    class_methods do
      extend ::Gitlab::Utils::Override
      include ::Gitlab::Utils::StrongMemoize

      override :all_strategies_ordered_by_preference
      def all_strategies_ordered_by_preference
        strong_memoize(:all_strategies_ordered_by_preference) do
          EE_STRATEGIES + super
        end
      end
    end
  end
end
