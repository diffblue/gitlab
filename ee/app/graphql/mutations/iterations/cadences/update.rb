# frozen_string_literal: true

module Mutations
  module Iterations
    module Cadences
      class Update < BaseMutation
        graphql_name 'IterationCadenceUpdate'

        authorize :admin_iteration_cadence

        argument :id, ::Types::GlobalIDType[::Iterations::Cadence], required: true,
          description: copy_field_description(Types::Iterations::CadenceType, :id)

        argument :title, GraphQL::Types::String, required: false,
          description: copy_field_description(Types::Iterations::CadenceType, :title)

        argument :duration_in_weeks, GraphQL::Types::Int, required: false,
          description: copy_field_description(Types::Iterations::CadenceType, :duration_in_weeks)

        argument :iterations_in_advance, GraphQL::Types::Int, required: false,
          description: copy_field_description(Types::Iterations::CadenceType, :iterations_in_advance)

        argument :start_date, Types::TimeType, required: false,
          description: copy_field_description(Types::Iterations::CadenceType, :start_date)

        argument :automatic, GraphQL::Types::Boolean, required: false,
          description: copy_field_description(Types::Iterations::CadenceType, :automatic)

        argument :active, GraphQL::Types::Boolean, required: false,
          description: copy_field_description(Types::Iterations::CadenceType, :active)

        argument :roll_over, GraphQL::Types::Boolean, required: false,
          description: copy_field_description(Types::Iterations::CadenceType, :roll_over)

        argument :description, GraphQL::Types::String, required: false,
          description: copy_field_description(Types::Iterations::CadenceType, :description)

        field :iteration_cadence, Types::Iterations::CadenceType, null: true,
          description: 'The updated iteration cadence.'

        def resolve(id:, **attrs)
          iteration_cadence = authorized_find!(id: id)

          response = ::Iterations::Cadences::UpdateService.new(iteration_cadence, current_user, attrs).execute

          response_object = response.success? ? response.payload[:iteration_cadence] : nil

          {
              iteration_cadence: response_object,
              errors: response.errors
          }
        end

        private

        def find_object(id:)
          # TODO: Remove coercion when working on https://gitlab.com/gitlab-org/gitlab/-/issues/257883
          id = ::Types::GlobalIDType[::Iterations::Cadence].coerce_isolated_input(id)
          GitlabSchema.find_by_gid(id)
        end
      end
    end
  end
end
