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

  # The fixture for this spec is generated automatically by
  #   bin/rake gitlab:usage_data:generate_sql_metrics_fixture
  #
  # Do not edit it manually!
  describe 'guard SQL queries against arbitrary changes' do
    # These metrics have SQL queries that rely on particular record IDs in
    # the database, or are otherwise unreliable.
    let(:ignored_metric_key_paths) do
      %w(
        counts.alert_bot_incident_issues
        counts.issues_created_gitlab_alerts
        counts.issues_created_manually_from_alerts
        counts.service_desk_issues
        counts_monthly.aggregated_metrics.xmau_plan
        counts_monthly.aggregated_metrics.xmau_project_management
        counts_monthly.aggregated_metrics.users_work_items
        counts_weekly.aggregated_metrics.xmau_plan
        counts_weekly.aggregated_metrics.xmau_project_management
        counts_weekly.aggregated_metrics.users_work_items
        hostname
        topology.duration_s
        usage_activity_by_stage_monthly.plan.service_desk_issues
        usage_activity_by_stage.plan.service_desk_issues
        uuid
      ).freeze
    end

    let(:stored_queries_fixture) do
      fixture_file('lib/gitlab/usage/sql_metrics_queries.json')
    end

    let(:stored_queries_hash) do
      deep_sort_hash(Gitlab::Json.parse(stored_queries_fixture).with_indifferent_access)
    end

    before do
      stub_usage_data_connections
      stub_object_store_settings
      stub_prometheus_queries
      remove_ignored_metrics!(stored_queries_hash)

      allow(License).to receive(:current).and_return(nil)
    end

    it 'does not change SQL metric queries' do
      report = Timecop.freeze(2021, 1, 1) do
        deep_sort_hash(described_class.for(output: :metrics_queries).with_indifferent_access)
      end

      remove_ignored_metrics!(report)

      message = <<~MSG
        # This example failed because it detected changes to Service Ping SQL metrics queries.
        #
        # Try regenerating the queries list and review the changes:
        #   bin/rake gitlab:usage_data:generate_sql_metrics_fixture
      MSG

      expect(report).to eq(stored_queries_hash), message
    end

    def remove_ignored_metrics!(hash)
      ignored_metric_key_paths.each do |key_path|
        *keys, last_key = key_path.split('.')
        keys.inject(hash, :fetch)[last_key] = nil
      end
    end

    def deep_sort_hash(object)
      if object.is_a?(Hash)
        object.map { |k, v| [k, deep_sort_hash(v)] }.sort.to_h
      else
        object
      end
    end
  end
end
