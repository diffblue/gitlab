# frozen_string_literal: true
module Analytics
  module CycleAnalytics
    class AggregatorService
      SUPPORTED_MODES = %I[incremental full].to_set

      def initialize(aggregation:, mode: :incremental, runtime_limiter: Analytics::CycleAnalytics::RuntimeLimiter.new)
        raise "Only :incremental and :full modes are supported" unless SUPPORTED_MODES.include?(mode)

        @aggregation = aggregation
        @mode = mode
        @runtime = 0
        @processed_records = 0
        @aggregation_finished = true
        @runtime_limiter = runtime_limiter
      end

      def execute
        run_aggregation(Issue)
        return unless aggregation.enabled?

        run_aggregation(MergeRequest)
        return unless aggregation.enabled?

        aggregation.refresh_last_run(mode)

        update_aggregation
      end

      private

      def update_aggregation
        aggregation.set_stats(mode, runtime, processed_records)

        if full_run? && fully_aggregated?
          aggregation.reset_full_run_cursors
        end

        aggregation.save!
      end

      attr_reader :aggregation, :mode, :update_params, :runtime, :processed_records, :runtime_limiter

      def run_aggregation(model)
        response = Analytics::CycleAnalytics::DataLoaderService.new(
          group: aggregation.namespace,
          model: model,
          context: Analytics::CycleAnalytics::AggregationContext.new(cursor: aggregation.cursor_for(mode, model),
            runtime_limiter: runtime_limiter)
        ).execute

        handle_response(model, response)
      end

      def handle_response(model, response)
        if response.success?
          aggregation.set_cursor(mode, model, response.payload[:context].cursor)

          @runtime += response.payload[:context].runtime
          @processed_records += response.payload[:context].processed_records

          @aggregation_finished = false if response.payload[:reason] != :model_processed

        else
          aggregation.reset
          aggregation.update!(enabled: false)
        end
      end

      def full_run?
        mode == :full
      end

      def fully_aggregated?
        @aggregation_finished
      end
    end
  end
end
