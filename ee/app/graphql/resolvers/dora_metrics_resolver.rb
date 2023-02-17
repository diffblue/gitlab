# frozen_string_literal: true

module Resolvers
  class DoraMetricsResolver < BaseResolver
    include Gitlab::Graphql::Authorize::AuthorizeResource

    authorizes_object!
    authorize :read_dora4_analytics
    type [::Types::DoraMetricType], null: true
    alias_method :container, :object

    argument :metric, Types::DoraMetricTypeEnum,
             required: true,
             description: 'Type of metric to return.'

    argument :start_date, Types::DateType,
             required: false,
             description: 'Date range to start from. Default is 3 months ago.'

    argument :end_date, Types::DateType,
             required: false,
             description: 'Date range to end at. Default is the current date.'

    argument :interval, Types::DoraMetricBucketingIntervalEnum,
             required: false,
             description: 'How the metric should be aggregrated. Defaults to `DAILY`. In the case of `ALL`, the `date` field in the response will be `null`.'

    argument :environment_tier, Types::DeploymentTierEnum,
             required: false,
             description: 'Deployment tier of the environments to return. Deprecated, please update to `environment_tiers` param.'

    argument :environment_tiers, [Types::DeploymentTierEnum],
             required: false,
             description: 'Deployment tiers of the environments to return. Defaults to `[PRODUCTION]`.'

    def resolve(params)
      # Backwards compatibility until %16.0
      if params[:environment_tier]
        params[:environment_tiers] ||= []
        params[:environment_tiers] |= [params[:environment_tier]]
      end

      params[:metrics] = [params[:metric]] if params[:metric]

      result = ::Dora::AggregateMetricsService
        .new(container: container, current_user: current_user, params: params)
        .execute

      raise Gitlab::Graphql::Errors::ArgumentError, result[:message] unless result[:status] == :success

      backwards_compatibility(result[:data], params[:metric])
    end

    private

    def backwards_compatibility(data, metric)
      data.map { |row| { 'date' => row['date'], 'value' => row[metric] } }
    end
  end
end
