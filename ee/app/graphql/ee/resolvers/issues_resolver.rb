# frozen_string_literal: true

module EE
  module Resolvers
    module IssuesResolver
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override

      prepended do
        argument :iteration_id, [::GraphQL::Types::ID, null: true],
                 required: false,
                 description: 'List of iteration Global IDs applied to the issue.'
        argument :iteration_wildcard_id, ::Types::IterationWildcardIdEnum,
                 required: false,
                 description: 'Filter by iteration ID wildcard.'
        argument :epic_id, GraphQL::Types::String,
                 required: false,
                 description: 'ID of an epic associated with the issues, "none" and "any" values are supported.'
        argument :weight, GraphQL::Types::String,
                 required: false,
                 description: 'Weight applied to the issue, "none" and "any" values are supported.'
      end

      override :resolve_with_lookahead
      def resolve_with_lookahead(**args)
        args[:iteration_id] = iteration_ids_from_args(args) if args[:iteration_id].present?
        args[:not][:iteration_id] = iteration_ids_from_args(args[:not]) if args.dig(:not, :iteration_id).present?
        prepare_iteration_wildcard_params(args)

        super
      end

      def ready?(**args)
        if iteration_params_not_mutually_exclusive?(args) || iteration_params_not_mutually_exclusive?(args.fetch(:not, {}))
          arg_str = mutually_exclusive_iteration_args.map { |x| x.to_s.camelize(:lower) }.join(', ')
          raise ::Gitlab::Graphql::Errors::ArgumentError, "only one of [#{arg_str}] arguments is allowed at the same time."
        end

        super
      end

      private

      # Originally accepted a raw model id. Now accept a gid, but allow a raw id
      # for backward compatibility
      def iteration_ids_from_args(args)
        args[:iteration_id].map do |id|
          ::GitlabSchema.parse_gid(id, expected_type: ::Iteration).model_id
        rescue ::Gitlab::Graphql::Errors::ArgumentError
          id
        end
      end

      def prepare_iteration_wildcard_params(args)
        args[:iteration_id] = args.delete(:iteration_wildcard_id) if args[:iteration_wildcard_id].present?
        args[:not][:iteration_id] = args[:not].delete(:iteration_wildcard_id) if args.dig(:not, :iteration_wildcard_id).present?
      end

      def iteration_params_not_mutually_exclusive?(args)
        args.slice(*mutually_exclusive_iteration_args).compact.size > 1
      end

      def mutually_exclusive_iteration_args
        [:iteration_id, :iteration_wildcard_id]
      end

      override :preloads
      def preloads
        super.merge(
          {
            sla_due_at: [:issuable_sla],
            metric_images: [:metric_images]
          }
        )
      end
    end
  end
end
