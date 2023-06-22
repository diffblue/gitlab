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

      service = ::Dora::AggregateMetricsService
        .new(container: container, current_user: current_user, params: params)

      result = service.execute

      raise Gitlab::Graphql::Errors::ArgumentError, result[:message] unless result[:status] == :success

      if params[:metric]
        # Backwards compatibility until %17.0
        single_metric_support(result[:data], params[:metric])
      else
        include_nil_values_for(result[:data], service)
      end
    end

    private

    def include_nil_values_for(data, dora_service)
      return data if dora_service.interval == 'all'
      return data unless lookahead.selects?(:date)

      filler_period =
        dora_service.interval == 'monthly' ? :month : :day

      # Need to transform data before filling gaps with nil values, Gitlab::Analytics::DateFiller
      # requires hash indexed by dates to work properly, For example:
      #
      # Sun, 28 Aug 2022=> { ... },
      # Mon, 29 Aug 2022=> { ... }
      transformed_data = data.each_with_object({}) { |item, hash| hash[item['date']] = item.except('date') }

      data_with_nil_values = ::Gitlab::Analytics::DateFiller.new(
        transformed_data,
        from: dora_service.start_date,
        to: dora_service.end_date,
        default_value: metrics_default_values,
        period: filler_period
      ).fill

      # Transforms data back to original format after nil values are included
      data_with_nil_values.map { |k, v| { 'date' => k }.merge(v) }
    end

    def single_metric_support(data, metric)
      data.each { |row| row['value'] = row[metric] }
    end

    def metrics_default_values
      selected_metrics.index_with { |_metric| nil }
    end

    def selected_metrics
      return unless lookahead&.selected?

      ::Dora::DailyMetrics::AVAILABLE_METRICS.select { |name| lookahead.selects?(name.to_sym) }
    end
  end
end
