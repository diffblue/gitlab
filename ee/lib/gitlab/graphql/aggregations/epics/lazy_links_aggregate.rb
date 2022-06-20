# frozen_string_literal: true

module Gitlab
  module Graphql
    module Aggregations
      module Epics
        class LazyLinksAggregate < ::Gitlab::Graphql::Aggregations::Issuables::LazyLinksAggregate
          def link_class
            Epic::RelatedEpicLink
          end
        end
      end
    end
  end
end
