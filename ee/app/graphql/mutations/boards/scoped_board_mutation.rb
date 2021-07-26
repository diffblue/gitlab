# frozen_string_literal: true

module Mutations
  module Boards
    module ScopedBoardMutation
      extend ActiveSupport::Concern

      prepended do
        argument :labels, [GraphQL::Types::String],
                 required: false,
                 description: copy_field_description(::Types::IssueType, :labels)

        argument :label_ids, [::Types::GlobalIDType[::Label]],
                 required: false,
                 description: 'IDs of labels to be added to the board.'
      end

      def resolve(**args)
        parsed_params = parse_arguments(args)

        super(**parsed_params)
      end

      def ready?(**args)
        if args.slice(*mutually_exclusive_args).size > 1
          arg_str = mutually_exclusive_args.map { |x| x.to_s.camelize(:lower) }.join(' or ')
          raise ::Gitlab::Graphql::Errors::ArgumentError, "one and only one of #{arg_str} is required"
        end

        super
      end

      private

      def parse_arguments(args = {})
        if args[:assignee_id]
          # TODO: remove this line when the compatibility layer is removed
          # See: https://gitlab.com/gitlab-org/gitlab/-/issues/257883
          args[:assignee_id] = ::Types::GlobalIDType[::User].coerce_isolated_input(args[:assignee_id])
          args[:assignee_id] = args[:assignee_id].model_id
        end

        if args[:milestone_id]
          # TODO: remove this line when the compatibility layer is removed
          # See: https://gitlab.com/gitlab-org/gitlab/-/issues/257883
          args[:milestone_id] = ::Types::GlobalIDType[::Milestone].coerce_isolated_input(args[:milestone_id])
          args[:milestone_id] = args[:milestone_id].model_id
        end

        args[:label_ids] &&= args[:label_ids].map do |label_id|
          ::GitlabSchema.parse_gid(label_id, expected_type: ::Label).model_id
        end

        # we need this because we also pass `gid://gitlab/Iteration/-4` or `gid://gitlab/Iteration/-4`
        # as `iteration_id` when we scope board to `Iteration::Predefined::Current` or `Iteration::Predefined::None`
        args[:iteration_id] = args[:iteration_id].model_id if args[:iteration_id]
        args
      end

      def mutually_exclusive_args
        [:labels, :label_ids]
      end
    end
  end
end
