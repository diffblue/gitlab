# frozen_string_literal: true

module Types
  module ComplianceManagement
    module MergeRequests
      class ComplianceViolationInputType < BaseInputObject
        graphql_name 'ComplianceViolationInput'

        argument :project_ids, [::Types::GlobalIDType[::Project]],
                 required: false,
                 description: 'Filter compliance violations by project.',
                 prepare: ->(ids, _ctx) { ids.map(&:model_id) }

        argument :merged_before, ::Types::DateType,
                 required: false,
                 description: 'Merge requests merged before this date (inclusive).'

        argument :merged_after, ::Types::DateType,
                 required: false,
                 description: 'Merge requests merged after this date (inclusive).'

        argument :target_branch, ::GraphQL::Types::String,
                 required: false,
                 description: 'Filter compliance violations by target branch.'
      end
    end
  end
end
