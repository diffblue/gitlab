# frozen_string_literal: true

module Resolvers
  module Ci
    class QueueingHistoryResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      type Types::Ci::QueueingHistoryType, null: true
      description <<~MD
        Time it took for ci job to be picked up by runner in percentiles. Available only to admins.
      MD

      argument :runner_type, ::Types::Ci::RunnerTypeEnum,
        required: false,
        description: 'Filter jobs by the type of runner that executed them.'

      argument :from_time, Types::TimeType,
        required: false,
        description: 'Start of the requested time frame. Defaults to 3 hours ago.'

      argument :to_time, Types::TimeType,
        required: false,
        description: 'End of the requested time frame. Defaults to current time.'

      def resolve(lookahead:, from_time:, to_time:, runner_type: nil)
        unless current_user&.can?(:read_jobs_statistics)
          raise_resource_not_available_error!("You don't have permissions to view CI jobs statistics")
        end

        result = ::Ci::CollectQueueingHistoryService.new(current_user: current_user,
          percentiles: selected_percentiles(lookahead),
          runner_type: runner_type,
          from_time: from_time,
          to_time: to_time
        ).execute

        raise Gitlab::Graphql::Errors::ArgumentError, result.message if result.error?

        { time_series: result.payload }
      end

      private

      def selected_percentiles(lookahead)
        ::Ci::CollectQueueingHistoryService::ALLOWED_PERCENTILES.filter do |p|
          lookahead.selection(:time_series).selects?("p#{p}")
        end
      end
    end
  end
end
