# frozen_string_literal: true

module EE
  module Types
    module WorkItems
      module Widgets
        module LinkedItemsType
          extend ActiveSupport::Concern
          include ::Gitlab::Utils::StrongMemoize

          prepended do
            field :blocked, GraphQL::Types::Boolean, null: true,
              description: 'Indicates the work item is blocked. Returns `null`' \
                           'if `linked_work_items` feature flag is disabled.'

            field :blocking_count, GraphQL::Types::Int, null: true,
              description: 'Count of items the work item is blocking. Returns `null`' \
                           'if `linked_work_items` feature flag is disabled.'

            field :blocked_by_count, GraphQL::Types::Int, null: true,
              description: 'Count of items blocking the work item. Returns `null`' \
                           'if `linked_work_items` feature flag is disabled.'

            def blocked
              return unless linked_items_enabled?

              aggregator_class.new(context, object.work_item.id) { |count| (count || 0) > 0 }
            end

            def blocked_by_count
              return unless linked_items_enabled?

              aggregator_class.new(context, object.work_item.id) { |count| count || 0 }
            end

            def blocking_count
              return unless linked_items_enabled?

              object.work_item.blocking_issues_count
            end

            private

            def aggregator_class
              ::Gitlab::Graphql::Aggregations::WorkItems::LazyLinksAggregate
            end

            def linked_items_enabled?
              object.work_item.project.linked_work_items_feature_flag_enabled?
            end
          end
        end
      end
    end
  end
end
