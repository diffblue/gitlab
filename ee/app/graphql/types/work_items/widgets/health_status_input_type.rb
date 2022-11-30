# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      class HealthStatusInputType < BaseInputObject
        graphql_name 'WorkItemWidgetHealthStatusInput'

        argument :health_status,
                 ::Types::HealthStatusEnum,
                 required: false,
                 description: 'Health status to be assigned to the work item.'
      end
    end
  end
end
