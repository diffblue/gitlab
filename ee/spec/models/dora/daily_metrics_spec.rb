# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dora::DailyMetrics, type: :model do
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
    subject { described_class.refresh!(environment, date) }

    around do |example|
      freeze_time { example.run }
    end

    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:environment) { create(:environment, project: project) }

    let(:date) { 1.day.ago.to_date }

    context 'with finished deployments' do
      before do
        # Deployment finished before the date
        previous_date = date - 1.day
        create(:deployment, :success, environment: environment, finished_at: previous_date)
        create(:deployment, :failed, environment: environment, finished_at: previous_date)

        # Deployment finished on the date
        create(:deployment, :success, environment: environment, finished_at: date)
        create(:deployment, :failed, environment: environment, finished_at: date)

        # Deployment finished after the date
        next_date = date + 1.day
        create(:deployment, :success, environment: environment, finished_at: next_date)
        create(:deployment, :failed, environment: environment, finished_at: next_date)
      end

      it 'inserts the daily metrics' do
        expect { subject }.to change { Dora::DailyMetrics.count }.by(1)

        metrics = environment.dora_daily_metrics.find_by_date(date)
        expect(metrics.deployment_frequency).to eq(1)
        expect(metrics.lead_time_for_changes_in_seconds).to be_nil
      end

      context 'when there is an existing daily metric' do
        before do
          create(:dora_daily_metrics, environment: environment, date: date, deployment_frequency: 0)
        end

        it 'updates the daily metrics' do
          expect { subject }.not_to change { Dora::DailyMetrics.count }

          metrics = environment.dora_daily_metrics.find_by_date(date)
          expect(metrics.deployment_frequency).to eq(1)
        end
      end
    end

    context 'with finished deployments and merged MRs' do
      before do
        merge_requests = []

        # Merged 1 day ago
        merge_requests << create(:merge_request, :with_merged_metrics, project: project).tap do |merge_request|
          merge_request.metrics.update!(merged_at: date - 1.day)
        end

        # Merged 2 days ago
        merge_requests << create(:merge_request, :with_merged_metrics, project: project).tap do |merge_request|
          merge_request.metrics.update!(merged_at: date - 2.days)
        end

        # Merged 3 days ago
        merge_requests << create(:merge_request, :with_merged_metrics, project: project).tap do |merge_request|
          merge_request.metrics.update!(merged_at: date - 3.days)
        end

        # Deployment finished on the date
        create(:deployment, :success, environment: environment, finished_at: date, merge_requests: merge_requests)
      end

      it 'inserts the daily metrics' do
        subject

        metrics = environment.dora_daily_metrics.find_by_date(date)
        expect(metrics.lead_time_for_changes_in_seconds).to eq(2.days.to_i) # median
      end

      context 'when there is an existing daily metric' do
        let!(:dora_daily_metrics) { create(:dora_daily_metrics, environment: environment, date: date, lead_time_for_changes_in_seconds: nil) }

        it 'updates the daily metrics' do
          expect { subject }
            .to change { dora_daily_metrics.reload.lead_time_for_changes_in_seconds }
            .from(nil)
            .to(2.days.to_i)
        end
      end
    end

    context 'with closed issues' do
      before do
        create(:issue, :incident, :closed, project: project, created_at: date - 7.days, closed_at: date)
        create(:issue, :incident, :closed, project: project, created_at: date - 5.days, closed_at: date)
        create(:issue, :incident, :closed, project: project, created_at: date - 3.days, closed_at: date)
        create(:issue, :incident, :closed, project: project, created_at: date - 1.day, closed_at: date)

        # Issues which shouldn't be included in calculation
        create(:issue, :closed, project: project, created_at: date - 1.year, closed_at: date) # not an incident
        create(:issue, :incident, project: project, created_at: date - 1.year) # not closed yet
        create(:issue, :incident, :closed, created_at: date - 1.year, closed_at: date) # different project
        create(:issue, :incident, :closed, project: project, created_at: date - 1.year, closed_at: date + 1.day) # different date
      end

      context 'for production environment' do
        let_it_be(:environment) { create(:environment, :production, project: project) }

        it 'inserts the daily metrics with time_to_restore_service' do
          subject

          metrics = environment.dora_daily_metrics.find_by_date(date)
          expect(metrics.time_to_restore_service_in_seconds).to eq(4.days.to_i) # median
        end
      end

      context 'for non-production environment' do
        it 'does not calculate time_to_restore_service daily metric' do
          subject

          metrics = environment.dora_daily_metrics.find_by_date(date)
          expect(metrics.time_to_restore_service_in_seconds).to be_nil
        end
      end
    end

    context 'when date is invalid type' do
      let(:date) { '2021-02-03' }

      it 'raises an error' do
        expect { subject }.to raise_error(ArgumentError)
      end
    end
  end

  describe '.aggregate_for!' do
    subject { described_class.aggregate_for!(metric, interval) }

    around do |example|
      freeze_time do
        example.run
      end
    end

    context 'when metric is deployment frequency' do
      before_all do
        create(:dora_daily_metrics, deployment_frequency: 3, date: '2021-01-01')
        create(:dora_daily_metrics, deployment_frequency: 3, date: '2021-01-01')
        create(:dora_daily_metrics, deployment_frequency: 2, date: '2021-01-02')
        create(:dora_daily_metrics, deployment_frequency: 2, date: '2021-01-02')
        create(:dora_daily_metrics, deployment_frequency: 1, date: '2021-01-03')
        create(:dora_daily_metrics, deployment_frequency: 1, date: '2021-01-03')
        create(:dora_daily_metrics, deployment_frequency: nil, date: '2021-01-04')
      end

      let(:metric) { described_class::METRIC_DEPLOYMENT_FREQUENCY }

      context 'when interval is all' do
        let(:interval) { described_class::INTERVAL_ALL }

        it 'aggregates the rows' do
          is_expected.to eq(12)
        end
      end

      context 'when interval is monthly' do
        let(:interval) { described_class::INTERVAL_MONTHLY }

        it 'aggregates the rows' do
          is_expected.to eq([{ 'date' => '2021-01-01', 'value' => 12 }])
        end
      end

      context 'when interval is daily' do
        let(:interval) { described_class::INTERVAL_DAILY }

        it 'aggregates the rows' do
          is_expected.to eq([{ 'date' => '2021-01-01', 'value' => 6 },
                             { 'date' => '2021-01-02', 'value' => 4 },
                             { 'date' => '2021-01-03', 'value' => 2 },
                             { 'date' => '2021-01-04', 'value' => nil }])
        end
      end

      context 'when interval is unknown' do
        let(:interval) { 'unknown' }

        it { expect { subject }.to raise_error(ArgumentError, 'Unknown interval') }
      end
    end

    shared_examples 'median metric' do |metric|
      subject { described_class.aggregate_for!(metric, interval) }

      before_all do
        column_name = :"#{metric}_in_seconds"

        create(:dora_daily_metrics, column_name => 100, :date => '2021-01-01')
        create(:dora_daily_metrics, column_name => 90, :date => '2021-01-01')
        create(:dora_daily_metrics, column_name => 80, :date => '2021-01-02')
        create(:dora_daily_metrics, column_name => 70, :date => '2021-01-02')
        create(:dora_daily_metrics, column_name => 60, :date => '2021-01-03')
        create(:dora_daily_metrics, column_name => 50, :date => '2021-01-03')
        create(:dora_daily_metrics, column_name => nil, :date => '2021-01-04')
      end

      context 'when interval is all' do
        let(:interval) { described_class::INTERVAL_ALL }

        it 'calculates the median' do
          is_expected.to eq(75)
        end
      end

      context 'when interval is monthly' do
        let(:interval) { described_class::INTERVAL_MONTHLY }

        it 'calculates the median' do
          is_expected.to eq([{ 'date' => '2021-01-01', 'value' => 75 }])
        end
      end

      context 'when interval is daily' do
        let(:interval) { described_class::INTERVAL_DAILY }

        it 'calculates the median' do
          is_expected.to eq([{ 'date' => '2021-01-01', 'value' => 95 },
                             { 'date' => '2021-01-02', 'value' => 75 },
                             { 'date' => '2021-01-03', 'value' => 55 },
                             { 'date' => '2021-01-04', 'value' => nil }])
        end
      end

      context 'when interval is unknown' do
        let(:interval) { 'unknown' }

        it { expect { subject }.to raise_error(ArgumentError, 'Unknown interval') }
      end
    end

    context 'when metric is lead time for changes' do
      include_examples 'median metric', described_class::METRIC_LEAD_TIME_FOR_CHANGES
    end

    context 'when metric is time_to_restore_service' do
      include_examples 'median metric', described_class::METRIC_TIME_TO_RESTORE_SERVICE
    end

    context 'when metric is unknown' do
      let(:metric) { 'unknown' }
      let(:interval) { described_class::INTERVAL_ALL }

      it { expect { subject }.to raise_error(ArgumentError, 'Unknown metric') }
    end
  end
end
