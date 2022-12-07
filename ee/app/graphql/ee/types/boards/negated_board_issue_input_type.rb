# frozen_string_literal: true

module EE
  module Types
    module Boards
      module NegatedBoardIssueInputType
        extend ActiveSupport::Concern

        prepended do
          argument :iteration_wildcard_id, ::Types::NegatedIterationWildcardIdEnum,
                   required: false,
                   description: 'Filter by iteration ID wildcard.'
          argument :health_status_filter, ::Types::HealthStatusEnum,
                   required: false,
                   description: 'Health status not applied to the issue.
                    Includes issues where health status is not set.'
        end
      end
    end
  end
end
