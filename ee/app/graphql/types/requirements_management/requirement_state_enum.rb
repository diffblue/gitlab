# frozen_string_literal: true

module Types
  module RequirementsManagement
    class RequirementStateEnum < BaseEnum
      graphql_name 'RequirementState'
      description 'State of a requirement'

      value 'OPENED', value: 'opened', description: 'Open requirement.'
      value 'ARCHIVED', value: 'archived', description: 'Archived requirement.'
    end
  end
end
