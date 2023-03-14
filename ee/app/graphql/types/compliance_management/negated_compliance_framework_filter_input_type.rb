# frozen_string_literal: true

module Types
  module ComplianceManagement
    class NegatedComplianceFrameworkFilterInputType < BaseInputObject
      graphql_name 'NegatedComplianceFrameworkFilters'

      argument :id, ::Types::GlobalIDType[::ComplianceManagement::Framework],
        required: false,
        description: 'ID of the compliance framework.',
        prepare: ->(id, _ctx) { id.model_id }
    end
  end
end
