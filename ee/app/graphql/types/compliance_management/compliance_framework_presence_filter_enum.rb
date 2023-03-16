# frozen_string_literal: true

module Types
  module ComplianceManagement
    class ComplianceFrameworkPresenceFilterEnum < BaseEnum
      graphql_name 'ComplianceFrameworkPresenceFilter'
      description 'ComplianceFramework of a project for filtering'

      value 'NONE', description: 'No compliance framework is assigned.', value: :none
      value 'ANY', description: 'Any compliance framework is assigned.', value: :any
    end
  end
end
