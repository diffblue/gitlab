# frozen_string_literal: true

module Types
  module ComplianceManagement
    class ComplianceFrameworkFilterInputType < ::Types::ComplianceManagement::ComplianceFrameworkFilterInputBaseType
      graphql_name 'ComplianceFrameworkFilters'

      argument :not, ::Types::ComplianceManagement::NegatedComplianceFrameworkFilterInputType,
        required: false,
        description: 'Negated compliance framework filter input.'
    end
  end
end
