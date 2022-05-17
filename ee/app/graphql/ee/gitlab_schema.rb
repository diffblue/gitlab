# frozen_string_literal: true

module EE
  module GitlabSchema
    extend ActiveSupport::Concern

    prepended do
      lazy_resolve ::Gitlab::Graphql::Aggregations::Epics::LazyEpicAggregate, :epic_aggregate
      lazy_resolve ::Gitlab::Graphql::Aggregations::Epics::LazyBlockAggregate, :block_aggregate
      lazy_resolve ::Gitlab::Graphql::Aggregations::Issues::LazyBlockAggregate, :block_aggregate
      lazy_resolve ::Gitlab::Graphql::Aggregations::VulnerabilityStatistics::LazyAggregate, :execute
      lazy_resolve ::Gitlab::Graphql::Aggregations::Vulnerabilities::LazyUserNotesCountAggregate, :execute
      lazy_resolve ::Gitlab::Graphql::Aggregations::SecurityOrchestrationPolicies::LazyDastProfileAggregate, :execute
    end
  end
end
