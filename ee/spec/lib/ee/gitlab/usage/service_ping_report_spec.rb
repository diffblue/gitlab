# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::ServicePingReport, :use_clean_rails_memory_store_caching,
feature_category: :service_ping do
  include UsageDataHelpers

  let(:usage_data) { { uuid: "1111", counts: { issue: 0 } } }

  context 'for conditional metrics inclusion' do
    before do
      stub_usage_data_connections
      stub_object_store_settings
      stub_prometheus_queries
      memoized_constants = Gitlab::UsageData::CE_MEMOIZED_VALUES
      memoized_constants += Gitlab::UsageData::EE_MEMOIZED_VALUES if defined? Gitlab::UsageData::EE_MEMOIZED_VALUES
      memoized_constants.each { |v| Gitlab::UsageData.clear_memoization(v) }
      stub_database_flavor_check('Cloud SQL for PostgreSQL')
      allow(License).to receive(:current)
    end

    it 'does not raise errors' do
      expect { described_class.for(output: :all_metrics_values) }.not_to raise_error
    end
  end

  context 'for output: :metrics_queries' do
    before do
      stub_usage_data_connections
      stub_object_store_settings
      stub_prometheus_queries
    end

    it 'returns queries that do not change between calls' do
      report = travel_to(Time.utc(2021, 1, 1)) do
        described_class.for(output: :metrics_queries)
      end

      other_report = travel_to(Time.utc(2021, 1, 1)) do
        described_class.for(output: :metrics_queries)
      end

      expect(report).to eq(other_report)
    end
  end
end
