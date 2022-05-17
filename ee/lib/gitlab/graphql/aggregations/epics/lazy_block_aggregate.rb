# frozen_string_literal: true

module Gitlab
  module Graphql
    module Aggregations
      module Epics
        class LazyBlockAggregate < ::Gitlab::Graphql::Aggregations::Issuables::LazyBlockAggregate
          def link_class
            Epic::RelatedEpicLink
          end
        end
      end
    end
  end
end
