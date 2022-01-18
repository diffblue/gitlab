# frozen_string_literal: true

module BulkImports
  module Groups
    module Graphql
      class GetIterationsQuery
        attr_reader :context

        def initialize(context:)
          @context = context
        end

        def to_s
          <<-'GRAPHQL'
          query($full_path: ID!, $cursor: String, $per_page: Int) {
            group(fullPath: $full_path) {
              iterations(first: $per_page, after: $cursor, includeAncestors: false) {
                page_info: pageInfo {
                  next_page: endCursor
                  has_next_page: hasNextPage
                }
                nodes {
                  iid
                  title
                  description
                  state
                  start_date: startDate
                  due_date: dueDate
                  created_at: createdAt
                  updated_at: updatedAt
                }
              }
            }
          }
          GRAPHQL
        end

        def variables
          {
            full_path: context.entity.source_full_path,
            cursor: context.tracker.next_page,
            per_page: ::BulkImports::Tracker::DEFAULT_PAGE_SIZE
          }
        end

        def base_path
          %w[data group iterations]
        end

        def data_path
          base_path << 'nodes'
        end

        def page_info_path
          base_path << 'page_info'
        end
      end
    end
  end
end
