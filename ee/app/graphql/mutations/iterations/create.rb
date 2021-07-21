# frozen_string_literal: true

module Mutations
  module Iterations
    class Create < BaseMutation
      include Mutations::ResolvesResourceParent

      graphql_name 'iterationCreate'

      authorize :create_iteration

      field :iteration,
            Types::IterationType,
            null: true,
            description: 'The created iteration.'

      argument :iterations_cadence_id,
               ::Types::GlobalIDType[::Iterations::Cadence],
               loads: ::Types::Iterations::CadenceType,
               required: false,
               description: 'Global ID of the iterations cadence to be assigned to newly created iteration.'

      argument :title,
               GraphQL::Types::String,
               required: false,
               description: 'The title of the iteration.'

      argument :description,
               GraphQL::Types::String,
               required: false,
               description: 'The description of the iteration.'

      argument :start_date,
               GraphQL::Types::String,
               required: false,
               description: 'The start date of the iteration.'

      argument :due_date,
               GraphQL::Types::String,
               required: false,
               description: 'The end date of the iteration.'

      def resolve(args)
        parent = authorized_resource_parent_find!(args)

        validate_arguments!(parent, args)

        response = ::Iterations::CreateService.new(parent, current_user, args).execute

        response_object = response.payload[:iteration] if response.success?
        response_errors = response.error? ? response.payload[:errors].full_messages : []

        {
            iteration: response_object,
            errors: response_errors
        }
      end

      private

      def validate_arguments!(parent, args)
        if args.except(:group_path, :project_path).empty?
          raise Gitlab::Graphql::Errors::ArgumentError, 'The list of iteration attributes is empty'
        end

        # Currently there is a single iteration cadence per group, so if `iterations_cadence_id` argument is not provided
        # we assign iteration to the only cadence in the group(see `Iteration#set_iterations_cadence`).
        # Once we introduce cadence CRUD support we need to specify to which iteration cadence a given iteration
        # belongs if there are more than once cadence in the group. Eventually `iterations_cadence_id` argument should
        # become required and there should be no need for group_path argument for iteration.
        if args[:iterations_cadence].blank? && parent.iterations_cadences.count > 1
          raise Gitlab::Graphql::Errors::ArgumentError, 'Please provide iterations_cadence_id argument to assign iteration to respective cadence'
        end
      end
    end
  end
end
