# frozen_string_literal: true

RSpec.shared_context 'includes EpicAggregate constants' do
  before do
    stub_const('EPIC_TYPE', Gitlab::Graphql::Aggregations::Epics::Constants::EPIC_TYPE)
    stub_const('ISSUE_TYPE', Gitlab::Graphql::Aggregations::Epics::Constants::ISSUE_TYPE)

    stub_const('OPENED_EPIC_STATE', Gitlab::Graphql::Aggregations::Epics::Constants::OPENED_EPIC_STATE)
    stub_const('CLOSED_EPIC_STATE', Gitlab::Graphql::Aggregations::Epics::Constants::CLOSED_EPIC_STATE)
    stub_const('OPENED_ISSUE_STATE', Gitlab::Graphql::Aggregations::Epics::Constants::OPENED_ISSUE_STATE)
    stub_const('CLOSED_ISSUE_STATE', Gitlab::Graphql::Aggregations::Epics::Constants::CLOSED_ISSUE_STATE)

    stub_const('ON_TRACK_STATUS', Gitlab::Graphql::Aggregations::Epics::Constants::ON_TRACK_STATUS)
    stub_const('NEEDS_ATTENTION_STATUS', Gitlab::Graphql::Aggregations::Epics::Constants::NEEDS_ATTENTION_STATUS)
    stub_const('AT_RISK_STATUS', Gitlab::Graphql::Aggregations::Epics::Constants::AT_RISK_STATUS)

    stub_const('WEIGHT_SUM', Gitlab::Graphql::Aggregations::Epics::Constants::WEIGHT_SUM)
    stub_const('HEALTH_STATUS_SUM', Gitlab::Graphql::Aggregations::Epics::Constants::HEALTH_STATUS_SUM)
    stub_const('COUNT', Gitlab::Graphql::Aggregations::Epics::Constants::COUNT)
  end
end
