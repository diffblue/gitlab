# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::ServicePing::PayloadKeysProcessor do
  context 'missing_instrumented_metrics_key_paths' do
    let(:payload) do
      {
        counts: { issues: 1, boards: 1 },
        topology: { duration_d: 100 },
        redis_hll_counters: { search: { i_search_total_monthly: 1 } }
      }
    end

    let(:metrics_definitions) do
      [
        instance_double(::Gitlab::Usage::MetricDefinition, key: 'counts.issues'),
        instance_double(::Gitlab::Usage::MetricDefinition, key: 'topology'),
        instance_double(::Gitlab::Usage::MetricDefinition, key: 'redis_hll_counters.search.i_search_total_monthly'),
        instance_double(::Gitlab::Usage::MetricDefinition, key: 'settings.collected_data_categories'),
        instance_double(::Gitlab::Usage::MetricDefinition, key: 'license_md5'),
        instance_double(::Gitlab::Usage::MetricDefinition, key: 'license_id'),
        instance_double(::Gitlab::Usage::MetricDefinition, key: 'historical_max_users'),
        instance_double(::Gitlab::Usage::MetricDefinition, key: 'licensee'),
        instance_double(::Gitlab::Usage::MetricDefinition, key: 'license_user_count'),
        instance_double(::Gitlab::Usage::MetricDefinition, key: 'license_billable_users'),
        instance_double(::Gitlab::Usage::MetricDefinition, key: 'license_starts_at'),
        instance_double(::Gitlab::Usage::MetricDefinition, key: 'license_expires_at'),
        instance_double(::Gitlab::Usage::MetricDefinition, key: 'license_plan'),
        instance_double(::Gitlab::Usage::MetricDefinition, key: 'license_add_ons'),
        instance_double(::Gitlab::Usage::MetricDefinition, key: 'license_trial'),
        instance_double(::Gitlab::Usage::MetricDefinition, key: 'license_subscription_id')
      ]
    end

    before do
      allow(::Gitlab::Usage::MetricDefinition).to receive(:with_instrumentation_class).and_return(metrics_definitions)
    end

    it 'returns the missing keys' do
      expect(described_class.new(payload).missing_instrumented_metrics_key_paths).to match_array(['settings.collected_data_categories'])
    end
  end
end
