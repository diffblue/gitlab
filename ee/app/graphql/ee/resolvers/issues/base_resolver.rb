# frozen_string_literal: true

module EE
  module Resolvers
    module Issues
      module BaseResolver
        extend ActiveSupport::Concern
        extend ::Gitlab::Utils::Override

        prepended do
          argument :epic_id, GraphQL::Types::String,
                   required: false,
                   description: 'ID of an epic associated with the issues, "none" and "any" values are supported.'
          argument :epic_wildcard_id, ::Types::EpicWildcardIdEnum,
                   required: false,
                   description: 'Filter by epic ID wildcard. Incompatible with epicId.'
          argument :include_subepics, GraphQL::Types::Boolean,
                   required: false,
                   description: 'Whether to include subepics when filtering issues by epicId.'
          argument :iteration_id, [::GraphQL::Types::ID, { null: true }],
                  required: false,
                  description: 'List of iteration Global IDs applied to the issue.'
          argument :iteration_title, GraphQL::Types::String,
                  required: false,
                  description: 'Filter by iteration title.'
          argument :iteration_wildcard_id, ::Types::IterationWildcardIdEnum,
                   required: false,
                   description: 'Filter by iteration ID wildcard.'
          argument :iteration_cadence_id, [::Types::GlobalIDType[::Iterations::Cadence]],
                   required: false,
                   description: 'Filter by a list of iteration cadence IDs.'
          argument :weight, GraphQL::Types::String,
                   required: false,
                   description: 'Weight applied to the issue, "none" and "any" values are supported.'
          argument :weight_wildcard_id, ::Types::WeightWildcardIdEnum,
                   required: false,
                   description: 'Filter by weight ID wildcard. Incompatible with weight.'
          argument :health_status_filter, ::Types::HealthStatusFilterEnum,
                   required: false,
                   description: 'Health status of the issue, "none" and "any" values are supported.'
        end

        def ready?(**args)
          args[:not] = args[:not].to_h if args[:not]

          params_not_mutually_exclusive(args, mutually_exclusive_weight_args)
          params_not_mutually_exclusive(args, mutually_exclusive_epic_args)
          params_not_mutually_exclusive(args, mutually_exclusive_iteration_args)
          params_not_mutually_exclusive(args.fetch(:not, {}), mutually_exclusive_iteration_args)

          super
        end

        private

        override :prepare_finder_params
        def prepare_finder_params(args)
          args[:not] = args[:not].to_h if args[:not]
          args[:iteration_id] = iteration_ids_from_args(args) if args[:iteration_id].present?
          args[:not][:iteration_id] = iteration_ids_from_args(args[:not]) if args.dig(:not, :iteration_id).present?
          args[:iteration_cadence_id] = iteration_cadence_ids_from_args(args) if args[:iteration_cadence_id].present?
          prepare_health_status_params(args)
          prepare_wildcard_params(args, :iteration_id, :iteration_wildcard_id)
          prepare_wildcard_params(args, :epic_id, :epic_wildcard_id)
          prepare_wildcard_params(args, :weight, :weight_wildcard_id)

          super
        end

        # Originally accepted a raw model id. Now accept a gid, but allow a raw id
        # for backward compatibility
        def iteration_ids_from_args(args)
          args[:iteration_id].map do |id|
            ::GitlabSchema.parse_gid(id, expected_type: ::Iteration).model_id
          rescue ::Gitlab::Graphql::Errors::ArgumentError
            id
          end
        end

        def iteration_cadence_ids_from_args(args)
          args[:iteration_cadence_id].map do |id|
            ::GitlabSchema.parse_gid(id, expected_type: ::Iterations::Cadence).model_id
          end
        end

        def prepare_wildcard_params(args, id_param, wildcard_param)
          args[id_param] = args.delete(wildcard_param) if args[wildcard_param].present?
          return unless args.dig(:not, wildcard_param).present?

          args[:not][id_param] = args[:not].delete(wildcard_param)
        end

        def prepare_health_status_params(args)
          # health_status argument is deprecated, use health_status_filter instead
          args[:health_status] = args.delete(:health_status_filter) if args[:health_status_filter].present?
        end

        def mutually_exclusive_iteration_args
          [:iteration_id, :iteration_wildcard_id]
        end

        def mutually_exclusive_epic_args
          [:epic_id, :epic_wildcard_id]
        end

        def mutually_exclusive_weight_args
          [:weight, :weight_wildcard_id]
        end
      end
    end
  end
end
