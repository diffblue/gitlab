# frozen_string_literal: true

module Mutations
  module Iterations
    module Cadences
      class Destroy < BaseMutation
        graphql_name 'IterationCadenceDestroy'

        authorize :admin_iteration_cadence

        argument :id,
                 ::Types::GlobalIDType[::Iterations::Cadence],
                 required: true,
                 description: copy_field_description(Types::Iterations::CadenceType, :id)

        field :group,
              ::Types::GroupType,
              null: false,
              description: 'Group the iteration cadence belongs to.'

        def resolve(id:)
          iteration_cadence = authorized_find!(id: id)

          response = ::Iterations::Cadences::DestroyService.new(iteration_cadence, current_user).execute

          {
            group: response.payload[:group],
            errors: response.errors
          }
        end
      end
    end
  end
end
