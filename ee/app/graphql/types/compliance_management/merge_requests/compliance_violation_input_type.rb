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
                 description: 'Merged date of merge requests merged before a compliance violation was created.'

        argument :merged_after, ::Types::DateType,
                 required: false,
                 description: 'Merged date of merge requests merged after a compliance violation was created.'
      end
    end
  end
end
