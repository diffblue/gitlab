# frozen_string_literal: true

module Resolvers
  class DoraMetricsResolver < BaseResolver
    include Gitlab::Graphql::Authorize::AuthorizeResource
    include LooksAhead

    authorizes_object!
    authorize :read_dora4_analytics
    type [::Types::DoraMetricType], null: true
    alias_method :container, :object

    argument :metric, Types::DoraMetricTypeEnum,
             required: false,
             description: 'Type of metric to return.',
             deprecated: { reason: 'Superseded by metrics fields. See `DoraMetric` type', milestone: '15.10' }

    argument :start_date, Types::DateType,
             required: false,
             description: 'Date range to start from. Default is 3 months ago.'

    argument :end_date, Types::DateType,
             required: false,
             description: 'Date range to end at. Default is the current date.'

    argument :interval, Types::DoraMetricBucketingIntervalEnum,
             required: false,
             description: 'How the metric should be aggregated. Defaults to `DAILY`. In the case of `ALL`, the `date` field in the response will be `null`.'

    argument :environment_tiers, [Types::DeploymentTierEnum],
             required: false,
             description: 'Deployment tiers of the environments to return. Defaults to `[PRODUCTION]`.'

    def resolve_with_lookahead(**params)
      params[:metrics] = Array(params[:metric] || selected_metrics)

      result = ::Dora::AggregateMetricsService
        .new(container: container, current_user: current_user, params: params)
        .execute

      raise Gitlab::Graphql::Errors::ArgumentError, result[:message] unless result[:status] == :success

      # Backwards compatibility until %17.0
      single_metric_support(result[:data], params[:metric]) if params[:metric]

      result[:data]
    end

    private

    def single_metric_support(data, metric)
      data.each { |row| row['value'] = row[metric] }
    end

    def selected_metrics
      return unless lookahead&.selected?

      Dora::DailyMetrics::AVAILABLE_METRICS.select { |name| lookahead.selects?(name.to_sym) }
    end
  end
end
