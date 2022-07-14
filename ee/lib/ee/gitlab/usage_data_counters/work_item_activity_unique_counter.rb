# frozen_string_literal: true

module EE
  module Gitlab
    module UsageDataCounters
      module WorkItemActivityUniqueCounter
        extend ActiveSupport::Concern

        WORK_ITEM_WEIGHT_CHANGED = 'users_updating_weight_estimate'

        class_methods do
          def track_work_item_weight_changed_action(author:)
            track_unique_action(WORK_ITEM_WEIGHT_CHANGED, author)
          end
        end
      end
    end
  end
end
