# frozen_string_literal: true

module Resolvers
  class IterationsResolver < BaseResolver
    include Gitlab::Graphql::Authorize::AuthorizeResource
    include TimeFrameArguments

    argument :state, Types::IterationStateEnum,
             required: false,
             description: 'Filter iterations by state.'
    argument :title, GraphQL::Types::String,
             required: false,
             description: 'Fuzzy search by title.'

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

    type Types::IterationType.connection_type, null: true

    def resolve(**args)
      validate_timeframe_params!(args)

      authorize!

      args[:id] = id_from_args(args)
      args[:iteration_cadence_ids] = parse_iteration_cadence_ids(args[:iteration_cadence_ids])
      args[:include_ancestors] = true if args[:include_ancestors].nil? && args[:iid].nil?

      iterations = IterationsFinder.new(context[:current_user], iterations_finder_params(args)).execute

      # Necessary for scopedPath computation in IterationPresenter
      context[:parent_object] = parent

      offset_pagination(iterations)
    end

    private

    def iterations_finder_params(args)
      {
        parent: parent,
        include_ancestors: args[:include_ancestors],
        id: args[:id],
        iid: args[:iid],
        iteration_cadence_ids: args[:iteration_cadence_ids],
        state: args[:state] || 'all',
        search_title: args[:title]
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
