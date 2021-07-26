# frozen_string_literal: true

module EE
  module Types
    module BoardType
      extend ActiveSupport::Concern

      prepended do
        field :assignee, type: ::Types::UserType, null: true,
              description: 'The board assignee.'

        field :epics, ::Types::Boards::BoardEpicType.connection_type, null: true,
              description: 'Epics associated with board issues.',
              resolver: ::Resolvers::BoardGroupings::EpicsResolver,
              complexity: 5

        field :labels, ::Types::LabelType.connection_type, null: true,
              description: 'Labels of the board.'

        field :milestone, type: ::Types::MilestoneType, null: true,
              description: 'The board milestone.'

        field :iteration, type: ::Types::IterationType, null: true,
              description: 'The board iteration.'

        field :weight, type: GraphQL::Types::Int, null: true,
              description: 'Weight of the board.'
      end
    end
  end
end
