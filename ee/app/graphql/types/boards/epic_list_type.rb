# frozen_string_literal: true

module Types
  module Boards
    class EpicListType < BaseObject
      graphql_name 'EpicList'
      description 'Represents an epic board list'

      include Gitlab::Utils::StrongMemoize

      accepts ::Boards::EpicList
      authorize :read_epic_board_list

      alias_method :list, :object

      field :id,
        type: ::Types::GlobalIDType[::Boards::EpicList],
        null: false, description: 'Global ID of the board list.'

      field :title, GraphQL::Types::String, null: false, description: 'Title of the list.'

      field :list_type, GraphQL::Types::String, null: false, description: 'Type of the list.'

      field :position, GraphQL::Types::Int,
        null: true, description: 'Position of the list within the board.'

      field :label, Types::LabelType, null: true, description: 'Label of the list.'

      field :collapsed, GraphQL::Types::Boolean,
        null: true,
        description: 'Indicates if this list is collapsed for this user.'

      field :epics, Types::EpicType.connection_type,
        null: true,
        resolver: Resolvers::Boards::BoardListEpicsResolver,
        description: 'List epics.'

      field :epics_count, GraphQL::Types::Int,
        null: true,
        description: 'Count of epics in the list.',
        deprecated: { reason: :renamed, replacement: 'metadata', milestone: '14.9' }

      field :metadata, Types::Boards::EpicListMetadataType,
        null: true, extras: [:lookahead], description: 'Epic list metatada.'

      def collapsed
        object.collapsed?(current_user)
      end

      def epics_count
        list_service.metadata([:epics_count])[:epics_count]
      end

      def metadata(lookahead: nil)
        required_metadata = []
        required_metadata << :epics_count if lookahead&.selects?(:epics_count)
        required_metadata << :total_weight if lookahead&.selects?(:total_weight)

        list_service.metadata(required_metadata)
      end

      def list_service
        ::Boards::Epics::ListService.new(list.epic_board.resource_parent, current_user, params)
      end

      def params
        (context[:epic_filters] || {}).merge(board: list.epic_board, list: list)
      end

      def title
        BatchLoader::GraphQL.for(object).batch do |lists, callback|
          ActiveRecord::Associations::Preloader.new(records: lists, associations: :label).call # rubocop: disable CodeReuse/ActiveRecord

          # all list titles are preloaded at this point
          lists.each { |list| callback.call(list, list.title) }
        end
      end
    end
  end
end
