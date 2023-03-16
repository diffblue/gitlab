# frozen_string_literal: true

module Types
  module ComplianceManagement
    class ComplianceFrameworkFilterInputType < ::Types::ComplianceManagement::ComplianceFrameworkFilterInputBaseType
      graphql_name 'ComplianceFrameworkFilters'

      argument :not, ::Types::ComplianceManagement::NegatedComplianceFrameworkFilterInputType,
        required: false,
        description: 'Negated compliance framework filter input.'

      argument :presence_filter, ::Types::ComplianceManagement::ComplianceFrameworkPresenceFilterEnum,
        required: false,
        as: :presence_filter,
        description: 'Checks presence of compliance framework of the project, "none" and "any" values are supported.'
    end
  end
end
