# frozen_string_literal: true

module Mutations
  module Iterations
    class Create < BaseMutation
      graphql_name 'iterationCreate'

      CADENCE_ID_DEPRECATION_MESSAGE = '`iterationCadenceId` is deprecated and will be removed in the future.' \
                                       ' This argument is ignored, because you can\'t create an iteration in a specific cadence.' \
                                       ' In the future only automatic iteration cadences will be allowed'

      include Mutations::ResolvesResourceParent

      authorize :create_iteration

      field :iteration,
            Types::IterationType,
            null: true,
            description: 'Created iteration.'

      argument :iterations_cadence_id,
               ::Types::GlobalIDType[::Iterations::Cadence],
               required: false,
               deprecated: { reason: CADENCE_ID_DEPRECATION_MESSAGE, milestone: '14.10' },
               description: 'Global ID of the iteration cadence to be assigned to the new iteration.' \
                            'Argument is ignored as it was only used behind the `iteration_cadences` feature flag.'

      argument :title,
               GraphQL::Types::String,
               required: false,
               description: 'Title of the iteration.'

      argument :description,
               GraphQL::Types::String,
               required: false,
               description: 'Description of the iteration.'

      argument :start_date,
               GraphQL::Types::String,
               required: false,
               description: 'Start date of the iteration.'

      argument :due_date,
               GraphQL::Types::String,
               required: false,
               description: 'End date of the iteration.'

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
        # Ignoring argument as it's not necessary for the legacy iteration creation feature.
        # Iteration will always be created in the first manual cadence for the group and create one
        # if it doesn't exist yet.
        args.delete(:iterations_cadence_id)

        if args.except(:group_path, :project_path).empty?
          raise Gitlab::Graphql::Errors::ArgumentError, 'The list of iteration attributes is empty'
        end

        if !parent.iteration_cadences_feature_flag_enabled? && args[:title].blank?
          raise Gitlab::Graphql::Errors::ArgumentError, "Title can't be blank"
        end
      end
    end
  end
end
