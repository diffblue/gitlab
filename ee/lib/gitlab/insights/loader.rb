# frozen_string_literal: true

module Gitlab
  module Insights
    class Loader
      def initialize(insights_entity:, current_user:, params:)
        @insights_entity = insights_entity
        @current_user = current_user
        @params = params
      end

      def execute
        case params.dig(:query, :data_source)
        when 'issuables', nil
          Executors::IssuableExecutor.new(
            query_params: params[:query][:params] || params[:query],
            current_user: current_user,
            insights_entity: insights_entity,
            chart_type: type_param,
            projects: projects_param
          ).execute
        when 'dora'
          Executors::DoraExecutor.new(
            query_params: params[:query][:params],
            current_user: current_user,
            insights_entity: insights_entity,
            chart_type: type_param,
            projects: projects_param
          ).execute
        else
          raise Gitlab::Insights::Validators::ParamsValidator::InvalidQueryError,
            'Unsupported query configuration found'
        end
      end

      private

      attr_reader :params, :current_user, :insights_entity

      def type_param
        @type_param ||= params[:type]
      end

      def projects_param
        @projects_param ||= params[:projects] || {}
      end
    end
  end
end
