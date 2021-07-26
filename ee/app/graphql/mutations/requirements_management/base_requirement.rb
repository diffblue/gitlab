# frozen_string_literal: true

module Mutations
  module RequirementsManagement
    class BaseRequirement < BaseMutation
      include ResolvesProject

      field :requirement, Types::RequirementsManagement::RequirementType,
            null: true,
            description: 'Requirement after mutation.'

      argument :title, GraphQL::Types::String,
               required: false,
               description: 'Title of the requirement.'

      argument :description, GraphQL::Types::String,
               required: false,
               description: 'Description of the requirement.'

      argument :project_path, GraphQL::Types::ID,
               required: true,
               description: 'Full project path the requirement is associated with.'
    end
  end
end
