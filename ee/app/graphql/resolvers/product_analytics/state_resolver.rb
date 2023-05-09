# frozen_string_literal: true

module Resolvers
  module ProductAnalytics
    class StateResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      authorizes_object!
      authorize :developer_access
      type ::Types::ProductAnalytics::StateEnum, null: true

      def resolve
        return unless Gitlab::CurrentSettings.product_analytics_enabled? && object.product_analytics_enabled?
        return 'create_instance' unless tracking_key?
        return 'loading_instance' if initializing?
        return 'waiting_for_events' if no_instance_data?

        'complete'
      end

      private

      def tracking_key?
        object.project_setting&.product_analytics_instrumentation_key&.present? ||
          object.project_setting&.jitsu_key&.present?
      end

      def initializing?
        !!Gitlab::Redis::SharedState.with { |redis| redis.get("project:#{object.id}:product_analytics_initializing") }
      end

      def no_instance_data?
        strong_memoize_with(:no_instance_data, object) do
          params = { query: { measures: ['TrackedEvents.count'] }, queryType: 'multi', path: 'load' }
          response = ::ProductAnalytics::CubeDataQueryService.new(container: object,
            current_user: current_user,
            params: params).execute

          # check for unknown errors and pass through to UI
          if response.error? && response.reason != :not_found
            error_message = response.payload['error'] || response.message
            raise ::Gitlab::Graphql::Errors::BaseError, "Error from Cube API: #{error_message}"
          end

          response.error? || response.payload.dig('results', 0, 'data', 0, 'TrackedEvents.count').to_i == 0
        end
      end
    end
  end
end
