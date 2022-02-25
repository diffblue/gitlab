# frozen_string_literal: true

module Mutations
  module Iterations
    class Update < BaseMutation
      graphql_name 'UpdateIteration'

      include Mutations::ResolvesGroup
      include ResolvesProject

      authorize :admin_iteration

      field :iteration,
            Types::IterationType,
            null: true,
            description: 'Updated iteration.'

      argument :group_path, GraphQL::Types::ID,
               required: true,
               description: 'Group of the iteration.'

      # rubocop:disable Graphql/IDType
      argument :id,
               GraphQL::Types::ID,
               required: true,
               description: 'Global ID of the iteration.'
      # rubocop:enable Graphql/IDType

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
        validate_arguments!(args)
        args[:id] = id_from_args(args)

        parent = resolve_group(full_path: args[:group_path]).try(:sync)
        validate_title_argument!(parent, args)
        iteration = authorized_find!(parent: parent, id: args[:id])

        response = ::Iterations::UpdateService.new(parent, current_user, args).execute(iteration)

        response_object = response.success? ? response.payload[:iteration] : nil
        response_errors = response.error? ? (response.payload[:errors] || response.message) : []

        {
            iteration: response_object,
            errors: response_errors
        }
      end

      private

      def find_object(parent:, id:)
        params = { parent: parent, id: id }

        IterationsFinder.new(context[:current_user], params).execute.first
      end

      def validate_arguments!(args)
        raise Gitlab::Graphql::Errors::ArgumentError, 'The list of iteration attributes is empty' if args.except(:group_path, :id).empty?
      end

      def validate_title_argument!(parent, args)
        if !parent.iteration_cadences_feature_flag_enabled? && args[:title].blank?
          raise Gitlab::Graphql::Errors::ArgumentError, "Title can't be blank"
        end
      end

      # Originally accepted a raw model id. Now accept a gid, but allow a raw id
      # for backward compatibility
      def id_from_args(args)
        GitlabSchema.parse_gid(args[:id], expected_type: ::Iteration).model_id
      rescue Gitlab::Graphql::Errors::ArgumentError
        args[:id].to_i
      end
    end
  end
end
