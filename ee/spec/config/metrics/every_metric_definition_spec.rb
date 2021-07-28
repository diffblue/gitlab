# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Every metric definition' do
  include UsageDataHelpers

  let(:usage_ping) { Gitlab::UsageData.uncached_data }
  let(:ignored_usage_ping_key_patterns) do
    %w(
      geo_node_usage
      license_add_ons
      testing_total_unique_counts
      user_auth_by_provider
    ).freeze
  end

  let(:usage_ping_key_paths) do
    parse_usage_ping_keys(usage_ping)
      .flatten
      .reject { |v| v =~ Regexp.union(ignored_usage_ping_key_patterns) }
      .sort
  end

  let(:ignored_metric_files_key_patterns) do
    %w(
      ci_runners_online
      geo_node_usage
      mock_ci
      mock_monitoring
      user_auth_by_provider
      user_dast_scans
      user_sast_scans
      user_dependency_scanning_scans
      user_container_scanning_scans
      user_secret_detection_scans
      user_coverage_fuzzing_scans
      user_api_fuzzing_scans
    ).freeze
  end

  let(:metric_files_key_paths) do
    Gitlab::Usage::MetricDefinition
      .definitions
      .reject { |k, v| v.status == 'removed' || v.key_path =~ Regexp.union(ignored_metric_files_key_patterns) }
      .keys
      .sort
  end

  let(:metric_files_with_schema) do
    Gitlab::Usage::MetricDefinition
      .definitions
      .select { |k, v| v.respond_to?(:value_json_schema) }
  end

  # Recursively traverse nested Hash of a generated Usage Ping to return an Array of key paths
  # in the dotted format used in metric definition YAML files, e.g.: 'count.category.metric_name'
  def parse_usage_ping_keys(object, key_path = [])
    if object.is_a?(Hash) && !object_with_schema?(key_path.join('.'))
      object.each_with_object([]) do |(key, value), result|
        result.append parse_usage_ping_keys(value, key_path + [key])
      end
    else
      key_path.join('.')
    end
  end

  def object_with_schema?(key_path)
    metric_files_with_schema.keys.include?(key_path)
  end

  before do
    allow(Gitlab::UsageData).to receive_messages(count: -1, distinct_count: -1, estimate_batch_distinct_count: -1, sum: -1, alt_usage_data: -1)
    allow(Gitlab::Geo).to receive(:enabled?).and_return(true)
    stub_licensed_features(requirements: true)
    stub_prometheus_queries
    stub_usage_data_connections
  end

  it 'is included in the Usage Ping hash structure' do
    expect(metric_files_key_paths).to match_array(usage_ping_key_paths)
  end

  context 'with value json schema' do
    it 'has a valid structure' do
      metric_files_with_schema.each do |key_path, metric|
        structure = usage_ping.dig(*key_path.split('.').map(&:to_sym))

        expect(structure).to match_metric_definition_schema(metric.value_json_schema)
      end
    end
  end
end
