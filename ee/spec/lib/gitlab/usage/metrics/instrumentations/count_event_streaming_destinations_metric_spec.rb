# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountEventStreamingDestinationsMetric do
  let_it_be(:destination) { create(:external_audit_event_destination) }

  it_behaves_like 'a correct instrumented metric value and query', { time_frame: 'all', data_source: 'database' } do
    let(:expected_value) { 1 }
    let(:expected_query) { 'SELECT COUNT("audit_events_external_audit_event_destinations"."id") FROM "audit_events_external_audit_event_destinations"' }
  end
end
