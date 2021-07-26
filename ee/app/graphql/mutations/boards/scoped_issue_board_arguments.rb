# frozen_string_literal: true

module Mutations
  module Boards
    module ScopedIssueBoardArguments
      extend ActiveSupport::Concern

      prepended do
        argument :assignee_id,
                 ::Types::GlobalIDType[::User],
                 required: false,
                 description: 'ID of user to be assigned to the board.'

        # Cannot pre-load ::Types::MilestoneType because we are also assigning values like:
        # ::Timebox::None(0), ::Timebox::Upcoming(-2) or ::Timebox::Started(-3), that cannot be resolved to a DB record.
        argument :milestone_id,
                 ::Types::GlobalIDType[::Milestone],
                 required: false,
                 description: 'ID of milestone to be assigned to the board.'

        # Cannot pre-load ::Types::IterationType because we are also assigning values like:
        # ::Iteration::Predefined::None(0) or ::Iteration::Predefined::Current(-4), that cannot be resolved to a DB record.
        argument :iteration_id,
                 ::Types::GlobalIDType[::Iteration],
                 required: false,
                 description: 'ID of iteration to be assigned to the board.'

        argument :weight,
                 GraphQL::Types::Int,
                 required: false,
                 description: 'Weight value to be assigned to the board.'
      end
    end
  end
end
