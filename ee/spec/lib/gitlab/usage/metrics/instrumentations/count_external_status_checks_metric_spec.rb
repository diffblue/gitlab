# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountExternalStatusChecksMetric do
  let_it_be(:checks) { create_list(:external_status_check, 3) }

  it_behaves_like 'a correct instrumented metric value and query', { time_frame: 'all', data_source: 'database' } do
    let(:expected_value) { 3 }
    let(:expected_query) { "SELECT COUNT(\"external_status_checks\".\"id\") FROM \"external_status_checks\"" }
  end
end
