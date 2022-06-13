# frozen_string_literal: true

module EE
  module Gitlab
    module UsageDataCounters
      module MergeRequestActivityUniqueCounter
        extend ActiveSupport::Concern

        MR_INVALID_APPROVERS = 'i_code_review_mr_with_invalid_approvers'

        class_methods do
          def track_invalid_approvers(merge_request:)
            track_unique_action_by_merge_request(MR_INVALID_APPROVERS, merge_request)
          end
        end
      end
    end
  end
end
