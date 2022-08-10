# frozen_string_literal: true

module Mutations
  module Iterations
    module Cadences
      class Create < BaseMutation
        graphql_name 'IterationCadenceCreate'

        include Mutations::ResolvesGroup

        authorize :create_iteration_cadence

        argument :group_path, GraphQL::Types::ID,
          required: true,
          description: "Group where the iteration cadence is created."

        argument :title, GraphQL::Types::String,
          required: false,
          description: copy_field_description(Types::Iterations::CadenceType, :title)

        argument :duration_in_weeks, GraphQL::Types::Int,
          required: false,
          description: copy_field_description(Types::Iterations::CadenceType, :duration_in_weeks)

        argument :iterations_in_advance, GraphQL::Types::Int,
          required: false,
          description: copy_field_description(Types::Iterations::CadenceType, :iterations_in_advance)

        argument :start_date, Types::TimeType,
          required: false,
          description: copy_field_description(Types::Iterations::CadenceType, :start_date)

        argument :automatic, GraphQL::Types::Boolean,
          required: true,
          description: copy_field_description(Types::Iterations::CadenceType, :automatic)

        argument :active, GraphQL::Types::Boolean,
          required: true,
          description: copy_field_description(Types::Iterations::CadenceType, :active)

        argument :roll_over, GraphQL::Types::Boolean,
          required: false,
          description: copy_field_description(Types::Iterations::CadenceType, :roll_over)

        argument :description, GraphQL::Types::String,
          required: false,
          description: copy_field_description(Types::Iterations::CadenceType, :description)

        field :iteration_cadence, Types::Iterations::CadenceType,
          null: true,
          description: 'Created iteration cadence.'

        def resolve(args)
          group = authorized_find!(group_path: args.delete(:group_path))

          response = ::Iterations::Cadences::CreateService.new(group, current_user, args).execute

          response_object = response.payload[:iteration_cadence] if response.success?
          response_errors = response.error? ? Array(response.errors) : []

          {
            iteration_cadence: response_object,
            errors: response_errors
          }
        end

        private

        def find_object(group_path:)
          resolve_group(full_path: group_path)
        end
      end
    end
  end
end
