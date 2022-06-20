# frozen_string_literal: true

module EE
  module GitlabSchema
    extend ActiveSupport::Concern

    prepended do
      lazy_resolve ::Gitlab::Graphql::Aggregations::Epics::LazyEpicAggregate, :epic_aggregate
      lazy_resolve ::Gitlab::Graphql::Aggregations::Epics::LazyLinksAggregate, :links_aggregate
      lazy_resolve ::Gitlab::Graphql::Aggregations::Issues::LazyLinksAggregate, :links_aggregate
      lazy_resolve ::Gitlab::Graphql::Aggregations::VulnerabilityStatistics::LazyAggregate, :execute
      lazy_resolve ::Gitlab::Graphql::Aggregations::Vulnerabilities::LazyUserNotesCountAggregate, :execute
      lazy_resolve ::Gitlab::Graphql::Aggregations::SecurityOrchestrationPolicies::LazyDastProfileAggregate, :execute
    end
  end
end
