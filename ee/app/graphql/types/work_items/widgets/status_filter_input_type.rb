# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      class StatusFilterInputType < BaseInputObject
        graphql_name 'StatusFilterInput'

        argument :status, ::Types::RequirementsManagement::RequirementStatusFilterEnum,
                 required: true,
                 description: 'Status of the work item.'
      end
    end
  end
end
