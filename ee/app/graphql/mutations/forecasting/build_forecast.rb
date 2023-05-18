# frozen_string_literal: true

module Mutations
  module Forecasting
    class BuildForecast < ::Mutations::BaseMutation
      graphql_name 'BuildForecast'

      authorize :build_forecast

      argument :type, GraphQL::Types::String, required: true, description: 'Type of the forecast.'

      argument :horizon, GraphQL::Types::Int, required: true, description: 'Number of data points to forecast.'

      argument :context_id, ::Types::GlobalIDType, required: true,
        description: 'Global ID of the context for the forecast to pick an appropriate model.'

      field :forecast, Types::Forecasting::ForecastType, null: false, description: 'Created forecast.'

      def ready?(type:, horizon:, context_id:)
        error = service_class.validate(type: type, context_class: context_id.model_class, horizon: horizon)

        raise Gitlab::Graphql::Errors::ArgumentError, error[:message] if error

        super
      end

      def resolve(type:, horizon:, context_id:)
        context = GitlabSchema.find_by_gid(context_id).sync

        raise_resource_not_available_error! unless context

        service = service_class.new(type: type, horizon: horizon, context: context)

        authorize!(service.forecast)

        result = service.execute

        raise Gitlab::Graphql::Errors::ArgumentError, result[:message] unless result[:status] == :success

        { forecast: result[:forecast] }
      end

      private

      def service_class
        ::Analytics::Forecasting::BuildForecastService
      end
    end
  end
end
