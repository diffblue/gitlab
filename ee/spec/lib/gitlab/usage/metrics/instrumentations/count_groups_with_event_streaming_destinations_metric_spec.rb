# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountGroupsWithEventStreamingDestinationsMetric do
  let_it_be(:group_with_destination) { create(:group) }
  let_it_be(:group_without_destination) { create(:group) }

  before do
    create(:external_audit_event_destination, group: group_with_destination)
  end

  it_behaves_like 'a correct instrumented metric value and query', { time_frame: 'all', data_source: 'database' } do
    let(:expected_value) { 1 }
    let(:expected_query) { 'SELECT COUNT(DISTINCT "namespaces"."id") FROM "namespaces" INNER JOIN "audit_events_external_audit_event_destinations" ON "audit_events_external_audit_event_destinations"."namespace_id" = "namespaces"."id" WHERE "namespaces"."type" = \'Group\'' }
  end
end
