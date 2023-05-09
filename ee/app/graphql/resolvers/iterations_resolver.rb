# frozen_string_literal: true

module Resolvers
  class IterationsResolver < BaseResolver
    include Gitlab::Graphql::Authorize::AuthorizeResource
    include TimeFrameArguments

    DEFAULT_IN_FIELD = :title

    argument :state, Types::IterationStateEnum,
             required: false,
             description: 'Filter iterations by state.'
    argument :title, GraphQL::Types::String,
             required: false,
             description: 'Fuzzy search by title.',
             deprecated: { reason: 'The argument will be removed in 15.4. Please use `search` and `in` fields instead', milestone: '15.4' }

    argument :search, GraphQL::Types::String,
             required: false,
             description: 'Query used for fuzzy-searching in the fields selected in the argument `in`. Returns all iterations if empty.'

    argument :in, [Types::IterationSearchableFieldEnum],
             required: false,
             description: "Fields in which the fuzzy-search should be performed with the query given in the argument `search`. Defaults to `[#{DEFAULT_IN_FIELD}]`."

    # rubocop:disable Graphql/IDType
    argument :id, GraphQL::Types::ID,
             required: false,
             description: 'Global ID of the Iteration to look up.'
    # rubocop:enable Graphql/IDType

    argument :iid, GraphQL::Types::ID,
             required: false,
             description: 'Internal ID of the Iteration to look up.'
    argument :include_ancestors, GraphQL::Types::Boolean,
             required: false,
             description: 'Whether to include ancestor iterations. Defaults to true.'

    argument :iteration_cadence_ids, [::Types::GlobalIDType[::Iterations::Cadence]],
              required: false,
              description: 'Global iteration cadence IDs by which to look up the iterations.'

    argument :sort, Types::IterationSortEnum,
              required: false,
              description: 'List iterations by sort order. If unspecified, an arbitrary order (subject to change) is used.'

    type Types::IterationType.connection_type, null: true

    def resolve(**args)
      validate_search_params!(args)

      authorize!

      args[:id] = id_from_args(args)
      args[:iteration_cadence_ids] = parse_iteration_cadence_ids(args[:iteration_cadence_ids])
      args[:include_ancestors] = true if args[:include_ancestors].nil? && args[:iid].nil?

      handle_search_params!(args)

      iterations = IterationsFinder.new(context[:current_user], iterations_finder_params(args)).execute

      # Necessary for scopedPath computation in IterationPresenter
      context[:parent_object] = parent

      offset_pagination(iterations)
    end

    private

    def validate_search_params!(args)
      if args[:title].present? && (args[:search].present? || args[:in].present?)
        raise Gitlab::Graphql::Errors::ArgumentError, "'title' is deprecated in favor of 'search'. Please use 'search'."
      end
    end

    def handle_search_params!(args)
      return unless args[:search] || args[:title]

      args[:in] = [DEFAULT_IN_FIELD] if args[:in].nil? || args[:in].empty?
      args[:search] = args[:title] if args[:title]
    end

    def iterations_finder_params(args)
      {
        parent: parent,
        include_ancestors: args[:include_ancestors],
        id: args[:id],
        iid: args[:iid],
        iteration_cadence_ids: args[:iteration_cadence_ids],
        state: args[:state] || 'all',
        search: args[:search],
        in: args[:in],
        sort: args[:sort]
      }.merge(transform_timeframe_parameters(args))
    end

    def parent
      @parent ||= object.respond_to?(:sync) ? object.sync : object
    end

    def authorize!
      Ability.allowed?(context[:current_user], :read_iteration, parent) || raise_resource_not_available_error!
    end

    # Originally accepted a raw model id. Now accept a gid, but allow a raw id
    # for backward compatibility
    def id_from_args(args)
      return unless args[:id].present?

      GitlabSchema.parse_gid(args[:id], expected_type: ::Iteration).model_id
    rescue Gitlab::Graphql::Errors::ArgumentError
      args[:id]
    end

    def parse_iteration_cadence_ids(iteration_cadence_ids)
      return unless iteration_cadence_ids.present?

      iteration_cadence_ids.map { |arg| GitlabSchema.parse_gid(arg, expected_type: ::Iterations::Cadence).model_id }
    end
  end
end
