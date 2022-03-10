# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountProjectsWithExternalStatusChecksMetric do
  let_it_be(:external_status_checks) { create_list(:external_status_check, 3) }
  let_it_be(:project) { create(:project) }

  it_behaves_like 'a correct instrumented metric value and query', { time_frame: 'all', data_source: 'database' } do
    let(:expected_value) { 3 }
    let(:expected_query) { "SELECT COUNT(DISTINCT \"external_status_checks\".\"project_id\") FROM \"external_status_checks\"" }
  end
end
