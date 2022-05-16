# frozen_string_literal: true
module Gitlab
  module Graphql
    module Board
      class IssuesConnectionExtension < GraphQL::Schema::Field::ConnectionExtension
        DEFAULT_CONNECTION_ARGS = %w[after before first last].freeze

        def apply
          # GraphQL::Schema::Field::ConnectionExtension redefines the
          # :after, :before, :first, and :last arguments. This causes a
          # DuplicateNamesError for graphql gem > 1.13.
          super unless (field.arguments.keys & DEFAULT_CONNECTION_ARGS).any?
        end

        def after_resolve(value:, object:, context:, **rest)
          ::Boards::Issues::ListService
            .initialize_relative_positions(object.list.board, context[:current_user], value.nodes)

          value
        end
      end
    end
  end
end
