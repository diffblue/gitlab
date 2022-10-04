# frozen_string_literal: true

module EE
  module Types
    module Boards
      module BoardIssueInputType
        extend ActiveSupport::Concern

        prepended do
          # NONE/ANY epic filter can not be negated
          argument :epic_wildcard_id, ::Types::Boards::EpicWildcardIdEnum,
                   required: false,
                   description: 'Filter by epic ID wildcard. Incompatible with epicId.'

          argument :iteration_wildcard_id, ::Types::IterationWildcardIdEnum,
                   required: false,
                   description: 'Filter by iteration ID wildcard.'

          argument :iteration_cadence_id, [::Types::GlobalIDType[::Iterations::Cadence]],
                   required: false,
                   description: 'Filter by a list of iteration cadence IDs.'

          argument :weight_wildcard_id, ::Types::Boards::WeightWildcardIdEnum,
                   required: false,
                   description: 'Filter by weight ID wildcard. Incompatible with weight.'

          argument :health_status_filter, ::Types::HealthStatusFilterEnum,
                    required: false,
                    as: :health_status,
                    description: 'Health status of the issue, "none" and "any" values are supported.'
        end
      end
    end
  end
end
