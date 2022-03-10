# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::ServicePingReport, :use_clean_rails_memory_store_caching do
  include UsageDataHelpers

  let(:usage_data) { { uuid: "1111", counts: { issue: 0 } } }

  context 'when feature merge_service_ping_instrumented_metrics enabled' do
    context 'for conditional metrics inclusion' do
      before do
        stub_feature_flags(merge_service_ping_instrumented_metrics: true)
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
  end
end
