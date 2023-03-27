# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::DoraPerformanceScoreCalculator, feature_category: :devops_reports do
  using RSpec::Parameterized::TableSyntax

  describe '.scores_for' do
    let(:project) { Project.new }
    let(:scores_date) { Date.today.beginning_of_month }

    where(:metric_name, :metric_value, :expected_score) do
      'deployment_frequency' | nil | nil
      'deployment_frequency' | 0.03 | :low
      'deployment_frequency' | 0.04 | :medium
      'deployment_frequency' | 1.0 | :high
      'deployment_frequency' | 1.1 | :high
      'lead_time_for_changes' | nil | nil
      'lead_time_for_changes' | 31.days | :low
      'lead_time_for_changes' | 30.days | :medium
      'lead_time_for_changes' | 7.days | :high
      'lead_time_for_changes' | 2.days | :high
      'time_to_restore_service' | nil | nil
      'time_to_restore_service' | 8.days | :low
      'time_to_restore_service' | 7.days | :medium
      'time_to_restore_service' | 1.day | :high
      'time_to_restore_service' | 1.hour | :high
      'change_failure_rate' | nil | nil
      'change_failure_rate' | 0.46 | :low
      'change_failure_rate' | 0.45 | :medium
      'change_failure_rate' | 0.15 | :high
      'change_failure_rate' | 0.14 | :high
    end

    with_them do
      it 'returns expected value' do
        metrics = Dora::DailyMetrics::AVAILABLE_METRICS.index_with { |_metric| 0 }
        metrics[metric_name] = metric_value

        allow(Analytics::DoraMetricsAggregator).to receive(:aggregate_for).with(
          projects: [project],
          start_date: scores_date,
          end_date: scores_date.end_of_month,
          environment_tiers: ['production'],
          interval: Dora::DailyMetrics::INTERVAL_ALL,
          metrics: Dora::DailyMetrics::AVAILABLE_METRICS).and_return([metrics])

        scores = described_class.scores_for(project, scores_date)

        expect(scores[metric_name]).to eq(expected_score)
      end
    end
  end
end
