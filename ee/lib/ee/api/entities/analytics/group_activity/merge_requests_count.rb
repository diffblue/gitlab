# frozen_string_literal: true

module EE
  module API
    module Entities
      module Analytics
        module GroupActivity
          class MergeRequestsCount < Grape::Entity
            expose :merge_requests_count, documentation: {
              type: "Integer",
              desc: "Number of merge requests. Limited to #{::Analytics::GroupActivityCalculator::RECENT_COUNT_LIMIT}",
              example: 3
            }
          end
        end
      end
    end
  end
end
