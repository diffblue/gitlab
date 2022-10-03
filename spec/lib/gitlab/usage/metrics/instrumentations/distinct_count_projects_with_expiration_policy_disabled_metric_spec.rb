# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::DistinctCountProjectsWithExpirationPolicyDisabledMetric do
  before do
    create(:container_expiration_policy, enabled: false)
  end

  it_behaves_like 'a correct instrumented metric value', { time_frame: 'all', data_source: 'database' } do
    let(:expected_value) { 1 }
  end
end
