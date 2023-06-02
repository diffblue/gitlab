# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dora::DailyMetrics, type: :model, feature_category: :value_stream_management do
  describe 'associations' do
    it { is_expected.to belong_to(:environment) }
  end

  describe '.in_range_of' do
    subject { described_class.in_range_of(from, to) }

    let_it_be(:daily_metrics_1) { create(:dora_daily_metrics, date: 1.day.ago.to_date) }
    let_it_be(:daily_metrics_2) { create(:dora_daily_metrics, date: 3.days.ago.to_date) }

    context 'when between 2 days ago and 1 day ago' do
      let(:from) { 2.days.ago.to_date }
      let(:to) { 1.day.ago.to_date }

      it 'returns the correct metrics' do
        is_expected.to eq([daily_metrics_1])
      end
    end

    context 'when between 3 days ago and 2 days ago' do
      let(:from) { 3.days.ago.to_date }
      let(:to) { 2.days.ago.to_date }

      it 'returns the correct metrics' do
        is_expected.to eq([daily_metrics_2])
      end
    end
  end

  describe '.for_environments' do
    subject { described_class.for_environments(environments) }

    let_it_be(:environment_a) { create(:environment) }
    let_it_be(:environment_b) { create(:environment) }
    let_it_be(:daily_metrics_a) { create(:dora_daily_metrics, environment: environment_a) }
    let_it_be(:daily_metrics_b) { create(:dora_daily_metrics, environment: environment_b) }

    context 'when targeting environment A only' do
      let(:environments) { environment_a }

      it 'returns the entry of environment A' do
        is_expected.to eq([daily_metrics_a])
      end
    end

    context 'when targeting environment B only' do
      let(:environments) { environment_b }

      it 'returns the entry of environment B' do
        is_expected.to eq([daily_metrics_b])
      end
    end
  end

  describe '.refresh!' do
    subject { described_class.refresh!(environment, date.to_date) }

    around do |example|
      freeze_time { example.run }
    end

    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:environment) { create(:environment, :production, project: project) }

    let_it_be(:date) { 1.day.ago }

    before do
      expect_next_instance_of(Dora::DeploymentFrequencyMetric) do |instance|
        expect(instance).to receive(:data_queries).and_return(deployment_frequency: Arel.sql('1'))
      end
      expect_next_instance_of(Dora::LeadTimeForChangesMetric) do |instance|
        expect(instance).to receive(:data_queries).and_return(lead_time_for_changes_in_seconds: Arel.sql('2'))
      end
      expect_next_instance_of(Dora::TimeToRestoreServiceMetric) do |instance|
        expect(instance).to receive(:data_queries).and_return(time_to_restore_service_in_seconds: Arel.sql('3'))
      end
      expect_next_instance_of(Dora::ChangeFailureRateMetric) do |instance|
        expect(instance).to receive(:data_queries).and_return(deployment_frequency: Arel.sql('1'), incidents_count: Arel.sql('4'))
      end
    end

    it 'refreshes with whatever metrics return' do
      subject

      metric = described_class.for_environments(environment).first!

      expect(metric).to have_attributes(
        deployment_frequency: 1,
        lead_time_for_changes_in_seconds: 2,
        time_to_restore_service_in_seconds: 3,
        incidents_count: 4
      )
    end

    context 'for production environment' do
      it 'recalculates performance scores' do
        expect(Dora::PerformanceScore).to receive(:refresh!).with(project, date.to_date)

        subject
      end
    end

    context 'for non-production environment' do
      let(:environment) { create(:environment, :staging, project: project) }

      it 'does not for scores recalculation' do
        expect(Dora::PerformanceScore).not_to receive(:refresh!)

        subject
      end
    end

    it 'when there is an existing metric already overwrites data' do
      create(
        :dora_daily_metrics,
        date: date,
        environment: environment,
        deployment_frequency: 90,
        lead_time_for_changes_in_seconds: 90,
        time_to_restore_service_in_seconds: 90,
        incidents_count: 90
      )

      subject

      metric = described_class.for_environments(environment).first!

      expect(metric).to have_attributes(
        deployment_frequency: 1,
        lead_time_for_changes_in_seconds: 2,
        time_to_restore_service_in_seconds: 3,
        incidents_count: 4
      )
    end
  end

  describe '.aggregate_for!', :freeze_time do
    subject { described_class.aggregate_for!([metric], interval) }

    let_it_be(:environment) { create :environment }

    context 'when metric is deployment frequency' do
      before_all do
        create(:dora_daily_metrics, environment: environment, deployment_frequency: 3, date: '2021-01-01')
        create(:dora_daily_metrics, environment: environment, deployment_frequency: 2, date: '2021-01-02')
        create(:dora_daily_metrics, environment: environment, deployment_frequency: 1, date: '2021-01-03')
        create(:dora_daily_metrics, environment: environment, deployment_frequency: nil, date: '2021-01-04')
      end

      let(:metric) { 'deployment_frequency' }

      context 'when interval is all' do
        let(:interval) { described_class::INTERVAL_ALL }

        it 'aggregates the rows' do
          is_expected.to eq([{ 'date' => nil, metric => 6 }])
        end
      end

      context 'when interval is monthly' do
        let(:interval) { described_class::INTERVAL_MONTHLY }

        it 'aggregates the rows' do
          is_expected.to eq([{ 'date' => Date.parse('2021-01-01'), metric => 6 }])
        end
      end

      context 'when interval is daily' do
        let(:interval) { described_class::INTERVAL_DAILY }

        it 'aggregates the rows' do
          is_expected.to eq([{ 'date' => Date.parse('2021-01-01'), metric => 3 },
                             { 'date' => Date.parse('2021-01-02'), metric => 2 },
                             { 'date' => Date.parse('2021-01-03'), metric => 1 },
                             { 'date' => Date.parse('2021-01-04'), metric => nil }])
        end
      end

      context 'when interval is unknown' do
        let(:interval) { 'unknown' }

        it { expect { subject }.to raise_error(ArgumentError, 'Unknown interval') }
      end
    end

    context 'when metric is change_failure_rate' do
      before_all do
        create(:dora_daily_metrics, environment: environment, deployment_frequency: 4, incidents_count: 3, date: '2021-01-01')
        create(:dora_daily_metrics, environment: environment, deployment_frequency: 2, incidents_count: 0, date: '2021-01-02')
        create(:dora_daily_metrics, environment: environment, deployment_frequency: 2, incidents_count: nil, date: '2021-01-03')
        create(:dora_daily_metrics, environment: environment, deployment_frequency: 0, incidents_count: 1, date: '2021-01-04')
        create(:dora_daily_metrics, environment: environment, deployment_frequency: nil, incidents_count: nil, date: '2021-01-05')
        create(:dora_daily_metrics, environment: environment, deployment_frequency: 0, incidents_count: 0, date: '2021-01-06')
      end

      let(:metric) { 'change_failure_rate' }

      context 'when interval is all' do
        let(:interval) { described_class::INTERVAL_ALL }

        it 'aggregates the rows' do
          is_expected.to eq([{ 'date' => nil, metric => 0.5 }])
        end
      end

      context 'when interval is monthly' do
        let(:interval) { described_class::INTERVAL_MONTHLY }

        it 'aggregates the rows' do
          is_expected.to eq([{ 'date' => Date.parse('2021-01-01'), metric => 0.5 }])
        end
      end

      context 'when interval is daily' do
        let(:interval) { described_class::INTERVAL_DAILY }

        it 'aggregates the rows' do
          is_expected.to eq([{ 'date' => Date.parse('2021-01-01'), metric => 0.75 },
                             { 'date' => Date.parse('2021-01-02'), metric => 0.0 },
                             { 'date' => Date.parse('2021-01-03'), metric => nil },
                             { 'date' => Date.parse('2021-01-04'), metric => 1.0 },
                             { 'date' => Date.parse('2021-01-05'), metric => nil },
                             { 'date' => Date.parse('2021-01-06'), metric => 0.0 }])
        end
      end

      context 'when interval is unknown' do
        let(:interval) { 'unknown' }

        it { expect { subject }.to raise_error(ArgumentError, 'Unknown interval') }
      end
    end

    shared_examples 'median metric' do |metric|
      subject { described_class.aggregate_for!([metric], interval) }

      before_all do
        column_name = :"#{metric}_in_seconds"

        create(:dora_daily_metrics, environment: environment, column_name => 100, :date => '2021-01-01')
        create(:dora_daily_metrics, environment: environment, column_name => 80, :date => '2021-01-02')
        create(:dora_daily_metrics, environment: environment, column_name => 60, :date => '2021-01-03')
        create(:dora_daily_metrics, environment: environment, column_name => 50, :date => '2021-01-04')
        create(:dora_daily_metrics, environment: environment, column_name => nil, :date => '2021-01-05')
      end

      context 'when interval is all' do
        let(:interval) { described_class::INTERVAL_ALL }

        it 'calculates the median' do
          is_expected.to eq([{ 'date' => nil, metric => 70 }])
        end
      end

      context 'when interval is monthly' do
        let(:interval) { described_class::INTERVAL_MONTHLY }

        it 'calculates the median' do
          is_expected.to eq([{ 'date' => Date.parse('2021-01-01'), metric => 70 }])
        end
      end

      context 'when interval is daily' do
        let(:interval) { described_class::INTERVAL_DAILY }

        it 'calculates the median' do
          is_expected.to eq([{ 'date' => Date.parse('2021-01-01'), metric => 100 },
                             { 'date' => Date.parse('2021-01-02'), metric => 80 },
                             { 'date' => Date.parse('2021-01-03'), metric => 60 },
                             { 'date' => Date.parse('2021-01-04'), metric => 50 },
                             { 'date' => Date.parse('2021-01-05'), metric => nil }])
        end
      end

      context 'when interval is unknown' do
        let(:interval) { 'unknown' }

        it { expect { subject }.to raise_error(ArgumentError, 'Unknown interval') }
      end
    end

    context 'when metric is lead time for changes' do
      include_examples 'median metric', 'lead_time_for_changes'
    end

    context 'when metric is time_to_restore_service' do
      include_examples 'median metric', 'time_to_restore_service'
    end

    context 'when metric is unknown' do
      let(:metric) { 'unknown' }
      let(:interval) { described_class::INTERVAL_ALL }

      it { expect { subject }.to raise_error(ArgumentError, 'Unknown metric') }
    end

    context 'with multiple metrics' do
      before_all do
        create(:dora_daily_metrics, environment: environment, deployment_frequency: 4, incidents_count: 3, date: '2021-01-01')
        create(:dora_daily_metrics, environment: environment, deployment_frequency: 2, incidents_count: 0, date: '2021-01-02')
        create(:dora_daily_metrics, environment: environment, deployment_frequency: 0, incidents_count: 1, date: '2021-01-03')
        create(:dora_daily_metrics, environment: environment, deployment_frequency: 0, incidents_count: 0, date: '2021-01-04')
      end

      subject { described_class.aggregate_for!(%w[deployment_frequency change_failure_rate], interval) }

      context 'when interval is all' do
        let(:interval) { described_class::INTERVAL_ALL }

        it 'aggregates the rows' do
          is_expected.to match_array([{ 'date' => nil, 'deployment_frequency' => 6, 'change_failure_rate' => be_within(0.005).of(4.0 / 6) }])
        end
      end

      context 'when interval is monthly' do
        let(:interval) { described_class::INTERVAL_MONTHLY }

        it 'aggregates the rows' do
          is_expected.to match_array([{ 'date' => Date.parse('2021-01-01'), 'deployment_frequency' => 6, 'change_failure_rate' => be_within(0.005).of(4.0 / 6) }])
        end
      end

      context 'when interval is daily' do
        let(:interval) { described_class::INTERVAL_DAILY }

        it 'aggregates the rows' do
          is_expected.to match_array([{ 'date' => Date.parse('2021-01-01'), 'deployment_frequency' => 4, 'change_failure_rate' => be_within(0.005).of(3.0 / 4) },
                             { 'date' => Date.parse('2021-01-02'), 'deployment_frequency' => 2, 'change_failure_rate' => 0 },
                             { 'date' => Date.parse('2021-01-03'), 'deployment_frequency' => 0, 'change_failure_rate' => 1 },
                             { 'date' => Date.parse('2021-01-04'), 'deployment_frequency' => 0, 'change_failure_rate' => 0 }])
        end
      end
    end
  end
end
