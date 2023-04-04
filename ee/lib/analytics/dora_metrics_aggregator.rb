# frozen_string_literal: true

module Analytics
  module DoraMetricsAggregator
    def self.aggregate_for(**params)
      ::Dora::DailyMetrics
        .for_environments(::Environment.for_project(params[:projects]).for_tier(params[:environment_tiers]))
        .in_range_of(params[:start_date], params[:end_date])
        .aggregate_for!(params[:metrics], params[:interval])
    end
  end
end
