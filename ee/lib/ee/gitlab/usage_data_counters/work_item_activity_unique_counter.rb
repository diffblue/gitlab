# frozen_string_literal: true

module EE
  module Gitlab
    module UsageDataCounters
      module WorkItemActivityUniqueCounter
        extend ActiveSupport::Concern

        WORK_ITEM_WEIGHT_CHANGED = 'users_updating_weight_estimate'
        WORK_ITEM_ITERATION_CHANGED = 'users_updating_work_item_iteration'

        class_methods do
          def track_work_item_weight_changed_action(author:)
            track_unique_action(WORK_ITEM_WEIGHT_CHANGED, author)
          end

          def track_work_item_iteration_changed_action(author:)
            track_unique_action(WORK_ITEM_ITERATION_CHANGED, author)
          end
        end
      end
    end
  end
end
