# frozen_string_literal: true

module Resolvers
  class TodoResolver < BaseResolver
    description 'Retrieve a single todo'

    type Types::TodoType, null: true

    argument :id, Types::GlobalIDType[Todo],
             required: true,
             description: 'ID of the Todo.'

    def resolve(id:)
      GitlabSchema.find_by_gid(id)
    end
  end
end
