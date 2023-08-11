# frozen_string_literal: true

module Gitlab
  module Graphql
    module Aggregations
      module WorkItems
        class LazyLinksAggregate < ::Gitlab::Graphql::Aggregations::Issuables::LazyLinksAggregate
          def link_class
            ::WorkItems::RelatedWorkItemLink
          end
        end
      end
    end
  end
end
