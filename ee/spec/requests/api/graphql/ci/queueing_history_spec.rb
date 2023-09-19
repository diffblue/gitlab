# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.ciQueueingHistory', :click_house, feature_category: :runner_fleet do
  include GraphqlHelpers
  include RunnerReleasesHelper
  include ClickHouseHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:instance_runner) { create(:ci_runner, :instance, :with_runner_manager) }
  let_it_be(:project_runner) { create(:ci_runner, :project, :with_runner_manager) }

  let_it_be(:admin) { create(:user, :admin) }
  let_it_be(:starting_time) { Time.utc(2023) }

  let(:runner_type) { nil }
  let(:from_time) { starting_time }
  let(:to_time) { starting_time + 3.hours }

  let(:params) { { runner_type: runner_type, from_time: from_time, to_time: to_time } }
  let(:query_path) do
    [
      [:ci_queueing_history, params],
      :time_series
    ]
  end

  let(:current_user) { admin }

  let(:query) do
    wrap_fields(query_graphql_path(query_path, 'time p50 p75 p90 p95 p99'))
  end

  let(:execute_query) do
    post_graphql(query, current_user: current_user)
  end

  let(:licensed_feature_available) { true }

  subject(:ci_queueing_history) do
    execute_query
    graphql_data_at(:ci_queueing_history)
  end

  before do
    stub_licensed_features(runner_performance_insights: licensed_feature_available)
  end

  context "when feature flag is disabled" do
    before do
      stub_feature_flags(clickhouse_ci_analytics: false)
    end

    it 'returns error' do
      execute_query
      expect_graphql_errors_to_include('Feature not enabled')
    end
  end

  shared_examples "returns unauthorized error" do
    it 'returns error' do
      execute_query
      expect_graphql_errors_to_include("You don't have permissions to view CI jobs statistics")
    end
  end

  context "when runner_performance_insights feature is disabled" do
    let(:licensed_feature_available) { false }

    include_examples "returns unauthorized error"
  end

  context "when user is nil" do
    let(:current_user) { nil }

    include_examples "returns unauthorized error"
  end

  context "when user is not admin" do
    let(:current_user) { create(:user) }

    include_examples "returns unauthorized error"
  end

  it 'returns empty time_series with no data' do
    expect(ci_queueing_history["timeSeries"]).to eq([])
  end

  it 'returns time_series grouped by 5 minute intervals' do
    builds = Array.new(2) do |i|
      time_shift = 7.minutes * i
      build(:ci_build,
        :success,
        created_at: starting_time + time_shift,
        queued_at: starting_time + time_shift,
        started_at: starting_time + 6.minutes + time_shift,
        finished_at: starting_time + 20.minutes + time_shift,
        runner: instance_runner,
        runner_manager: instance_runner.runner_managers.first)
    end

    insert_ci_builds_to_click_house(builds)

    expect(ci_queueing_history["timeSeries"]).to eq([
      { 'p50' => 360, 'p75' => 360, 'p90' => 360, 'p95' => 360, 'p99' => 360,
        'time' => (starting_time + 5.minutes).utc.iso8601 },
      { 'p50' => 360, 'p75' => 360, 'p90' => 360, 'p95' => 360, 'p99' => 360,
        'time' => (starting_time + 10.minutes).utc.iso8601 }
    ])
  end

  it 'properly handles from_time and to_time' do
    builds = [from_time - 1.second,
      from_time,
      to_time,
      to_time + 5.minutes + 1.second].map do |started_at|
      build(:ci_build,
        :success,
        created_at: started_at - 1.minute,
        queued_at: started_at - 1.minute,
        started_at: started_at,
        finished_at: started_at + 10.minutes,
        runner: instance_runner,
        runner_manager: instance_runner.runner_managers.first)
    end

    insert_ci_builds_to_click_house(builds)

    expect(ci_queueing_history['timeSeries']).to eq([
      { 'p50' => 60, 'p75' => 60, 'p90' => 60, 'p95' => 60, 'p99' => 60,
        "time" => from_time.utc.iso8601 },
      { 'p50' => 60, 'p75' => 60, 'p90' => 60, 'p95' => 60, 'p99' => 60,
        'time' => to_time.utc.iso8601 }
    ])
  end

  context 'when from_time and to_time are not specified' do
    let(:from_time) { nil }
    let(:to_time) { nil }

    around do |example|
      travel_to(starting_time + 3.hours) do
        example.run
      end
    end

    it 'defaults time frame to the last 3 hours' do
      from_time_default = starting_time
      to_time_default = starting_time + 3.hours
      builds = [from_time_default - 1.second,
        from_time_default,
        to_time_default,
        to_time_default + 5.minutes + 1.second].map do |started_at|
        build(:ci_build,
          :success,
          created_at: started_at - 1.minute,
          queued_at: started_at - 1.minute,
          started_at: started_at,
          finished_at: started_at + 10.minutes,
          runner: instance_runner,
          runner_manager: instance_runner.runner_managers.first)
      end

      insert_ci_builds_to_click_house(builds)

      expect(ci_queueing_history['timeSeries']).to eq([
        { 'p50' => 60, 'p75' => 60, 'p90' => 60, 'p95' => 60, 'p99' => 60,
          "time" => from_time_default.utc.iso8601 },
        { 'p50' => 60, 'p75' => 60, 'p90' => 60, 'p95' => 60, 'p99' => 60,
          'time' => to_time_default.utc.iso8601 }
      ])
    end
  end

  context 'when runner_type is specified' do
    let(:runner_type) { :PROJECT_TYPE }

    it 'filters data by runner type' do
      builds = [
        build(:ci_build,
          :success,
          created_at: starting_time,
          queued_at: starting_time,
          started_at: starting_time + 1.minute,
          finished_at: starting_time + 10.minutes,
          runner: instance_runner,
          runner_manager: instance_runner.runner_managers.first),
        build(:ci_build,
          :success,
          created_at: starting_time + 10.minutes,
          queued_at: starting_time + 10.minutes,
          started_at: starting_time + 10.minutes + 3.seconds,
          finished_at: starting_time + 11.minutes,
          runner: project_runner,
          runner_manager: project_runner.runner_managers.first)
      ]

      insert_ci_builds_to_click_house(builds)

      expect(ci_queueing_history['timeSeries']).to eq([
        { 'p50' => 3, 'p75' => 3, 'p90' => 3, 'p95' => 3, 'p99' => 3,
          'time' => (starting_time + 10.minutes).utc.iso8601 }
      ])
    end
  end

  context 'when requesting more that TIME_BUCKETS_LIMIT' do
    let(:to_time) { starting_time + 190.minutes }

    it 'returns error' do
      execute_query

      expect_graphql_errors_to_include('Maximum of 37 5-minute intervals can be requested')
    end
  end
end
