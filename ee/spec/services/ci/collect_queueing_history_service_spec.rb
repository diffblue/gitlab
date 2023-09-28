# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ci::CollectQueueingHistoryService, :click_house, :enable_admin_mode, feature_category: :runner_fleet do
  include ClickHouseHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:instance_runner) { create(:ci_runner, :instance, :with_runner_manager) }
  let_it_be(:project_runner) { create(:ci_runner, :project, :with_runner_manager) }
  let_it_be(:group_runner) { create(:ci_runner, :group, :with_runner_manager) }

  let_it_be(:starting_time) { Time.utc(2023) }

  let(:current_user) { create(:user, :admin) }
  let(:percentiles) { [50, 75, 90, 95, 99] }
  let(:runner_type) { nil }
  let(:from_time) { starting_time }
  let(:to_time) { starting_time + 3.hours }

  let(:service) do
    described_class.new(current_user: current_user,
      percentiles: percentiles,
      runner_type: runner_type,
      from_time: from_time,
      to_time: to_time)
  end

  let(:licensed_feature_available) { true }

  before do
    stub_licensed_features(runner_performance_insights: licensed_feature_available)
  end

  subject(:result) { service.execute }

  context "when feature flag is disabled" do
    before do
      stub_feature_flags(clickhouse_ci_analytics: false)
    end

    it 'returns error' do
      expect(result.error?).to eq(true)
      expect(result.errors).to contain_exactly('Feature clickhouse_ci_analytics not enabled')
    end
  end

  shared_examples "returns Not allowed error" do
    it 'returns error' do
      expect(result.error?).to eq(true)
      expect(result.errors).to contain_exactly('Not allowed')
    end
  end

  context "when runner_performance_insights feature is disabled" do
    let(:licensed_feature_available) { false }

    include_examples "returns Not allowed error"
  end

  context "when user is nil" do
    let(:current_user) { nil }

    include_examples "returns Not allowed error"
  end

  context "when user is not admin" do
    let(:current_user) { create(:user) }

    include_examples "returns Not allowed error"
  end

  context "when requesting invalid percentiles" do
    let(:percentiles) { [88] }

    it 'returns an error' do
      expect(result.error?).to eq(true)
      expect(result.errors).to eq(['At least one of 50, 75, 90, 95, 99 percentiles should be requested'])
    end
  end

  context 'when requesting only some percentiles' do
    let(:percentiles) { [95, 90] }

    it 'returns only those percentiles' do
      build = build(:ci_build,
        :success,
        created_at: starting_time,
        queued_at: starting_time,
        started_at: starting_time + 2.seconds,
        finished_at: starting_time + 1.minute,
        runner: instance_runner,
        runner_manager: instance_runner.runner_managers.first)

      insert_ci_builds_to_click_house([build])

      expect(result.success?).to eq(true)
      expect(result.payload).to eq([
        { "p90" => 2.seconds, "p95" => 2.seconds, "time" => starting_time }
      ])
    end
  end

  it 'returns empty result if there is no data in ClickHouse' do
    expect(result.success?).to eq(true)
    expect(result.payload).to eq([])
  end

  it 'returns equal percentiles for a single build', :freeze_time do
    build = build(:ci_build,
      :success,
      created_at: starting_time,
      queued_at: starting_time,
      started_at: starting_time + 2.seconds,
      finished_at: starting_time + 1.minute,
      runner: instance_runner,
      runner_manager: instance_runner.runner_managers.first)

    insert_ci_builds_to_click_house([build])

    expect(result.success?).to eq(true)
    expect(result.payload).to eq([
      { "p50" => 2.seconds, "p75" => 2.seconds, "p90" => 2.seconds, "p95" => 2.seconds, "p99" => 2.seconds,
        "time" => starting_time }
    ])
  end

  it 'groups builds by 5 minute intervals of started_at' do
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

    expect(result.success?).to eq(true)

    expect(result.payload).to eq([
      { "p50" => 6.minutes, "p75" => 6.minutes, "p90" => 6.minutes, "p95" => 6.minutes, "p99" => 6.minutes,
        "time" => starting_time + 5.minutes },
      { "p50" => 6.minutes, "p75" => 6.minutes, "p90" => 6.minutes, "p95" => 6.minutes, "p99" => 6.minutes,
        "time" => starting_time + 10.minutes }
    ])
  end

  it 'properly calculates percentiles' do
    builds = Array.new(10) do |i|
      queueing_delay = 1 + i.seconds

      build(:ci_build,
        :success,
        created_at: starting_time,
        queued_at: starting_time,
        started_at: starting_time + queueing_delay,
        finished_at: starting_time + queueing_delay + 1.minute,
        runner: instance_runner,
        runner_manager: instance_runner.runner_managers.first)
    end

    insert_ci_builds_to_click_house(builds)

    expect(result.success?).to eq(true)

    # We don't calculate exact quantiles, so 10 seconds for 95 and 99 percentiles become 9 seconds
    expect(result.payload).to eq([
      { "p50" => 5.seconds, "p75" => 7.seconds, "p90" => 9.seconds, "p95" => 9.seconds, "p99" => 9.seconds,
        "time" => starting_time }
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

    expect(result.success?).to eq(true)

    expect(result.payload).to eq([
      { "p50" => 1.minute, "p75" => 1.minute, "p90" => 1.minute, "p95" => 1.minute, "p99" => 1.minute,
        "time" => from_time },
      { "p50" => 1.minute, "p75" => 1.minute, "p90" => 1.minute, "p95" => 1.minute, "p99" => 1.minute,
        "time" => to_time }
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

      expect(result.success?).to eq(true)

      expect(result.payload).to eq([
        { "p50" => 1.minute, "p75" => 1.minute, "p90" => 1.minute, "p95" => 1.minute, "p99" => 1.minute,
          "time" => from_time_default },
        { "p50" => 1.minute, "p75" => 1.minute, "p90" => 1.minute, "p95" => 1.minute, "p99" => 1.minute,
          "time" => to_time_default }
      ])
    end
  end

  context "when requesting more that TIME_BUCKETS_LIMIT" do
    let(:to_time) { starting_time + 190.minutes }

    it 'returns error' do
      expect(result.error?).to eq(true)

      expect(result.errors).to eq(['Maximum of 37 5-minute intervals can be requested'])
    end
  end

  context 'when runner_type is specified' do
    let(:runner_type) { :group_type }

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
          runner: group_runner,
          runner_manager: group_runner.runner_managers.first)
      ]

      insert_ci_builds_to_click_house(builds)

      expect(result.success?).to eq(true)

      expect(result.payload).to eq([
        { "p50" => 3.seconds, "p75" => 3.seconds, "p90" => 3.seconds, "p95" => 3.seconds, "p99" => 3.seconds,
          "time" => starting_time + 10.minutes }
      ])
    end
  end
end
