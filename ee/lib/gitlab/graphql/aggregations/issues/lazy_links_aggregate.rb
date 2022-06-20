# frozen_string_literal: true

module Gitlab
  module Graphql
    module Aggregations
      module Issues
        class LazyLinksAggregate < ::Gitlab::Graphql::Aggregations::Issuables::LazyLinksAggregate
          def link_class
            IssueLink
          end
        end
      end
    end
  end
end
