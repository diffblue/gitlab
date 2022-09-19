# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      class StatusInputType < BaseInputObject
        graphql_name 'StatusInput'

        argument :status, ::Types::RequirementsManagement::TestReportStateEnum,
                 required: true,
                 description: 'Status to assign to the work item.'
      end
    end
  end
end
