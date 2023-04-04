# frozen_string_literal: true

module Analytics
  module DoraPerformanceScoreCalculator
    SCORES_BOUNDARIES = {
      Dora::DeploymentFrequencyMetric::METRIC_NAME => { low: 0.033, high: 1.0, reverse: true },
      Dora::LeadTimeForChangesMetric::METRIC_NAME => { low: 30.days, high: 7.days },
      Dora::TimeToRestoreServiceMetric::METRIC_NAME => { low: 7.days, high: 1.day },
      Dora::ChangeFailureRateMetric::METRIC_NAME => { low: 0.45, high: 0.15 }
    }.freeze

    class << self
      def scores_for(project, date)
        date = date.beginning_of_month.to_date
        aggregated_metrics = ::Analytics::DoraMetricsAggregator.aggregate_for(
          projects: [project],
          start_date: date,
          end_date: date.end_of_month,
          environment_tiers: ['production'],
          interval: Dora::DailyMetrics::INTERVAL_ALL,
          metrics: Dora::DailyMetrics::AVAILABLE_METRICS).first

        transform_metrics_to_scores(aggregated_metrics)
      end

      private

      def transform_metrics_to_scores(aggregated_metrics)
        result = {}
        Dora::DailyMetrics::AVAILABLE_METRICS.each do |metric|
          result[metric] = calculate_score(metric, aggregated_metrics[metric])
        end
        result
      end

      def calculate_score(metric, value)
        return unless value
        return calculate_reverse_score(metric, value) if SCORES_BOUNDARIES[metric][:reverse]

        return :low if value > SCORES_BOUNDARIES[metric][:low]
        return :high if value <= SCORES_BOUNDARIES[metric][:high]

        :medium
      end

      def calculate_reverse_score(metric, value)
        return :low if value < SCORES_BOUNDARIES[metric][:low]
        return :high if value >= SCORES_BOUNDARIES[metric][:high]

        :medium
      end
    end
  end
end
