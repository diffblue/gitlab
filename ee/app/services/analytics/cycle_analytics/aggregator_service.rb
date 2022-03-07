# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    class AggregatorService
      def initialize(aggregation:, mode: :incremental)
        raise "Only :incremental mode is supported" if mode != :incremental

        @aggregation = aggregation
        @mode = mode
        @update_params = {
          runtime_column => (aggregation[runtime_column] + [0]).last(10),
          processed_records_column => (aggregation[processed_records_column] + [0]).last(10)
        }
      end

      def execute
        run_aggregation(Issue)
        run_aggregation(MergeRequest)

        update_params["last_#{mode}_run_at"] = Time.current

        aggregation.update!(update_params)
      end

      private

      attr_reader :aggregation, :mode, :update_params

      def run_aggregation(model)
        response = Analytics::CycleAnalytics::DataLoaderService.new(
          group: aggregation.group,
          model: model,
          context: Analytics::CycleAnalytics::AggregationContext.new(cursor: cursor_for(model))
        ).execute

        handle_response(model, response)
      end

      def handle_response(model, response)
        if response.success?
          update_params[updated_at_column(model)] = response.payload[:context].cursor[:updated_at]
          update_params[id_column(model)] = response.payload[:context].cursor[:id]
          update_params[runtime_column][-1] += response.payload[:context].runtime
          update_params[processed_records_column][-1] += response.payload[:context].processed_records
        else
          update_params.clear
          update_params[:enabled] = false
        end
      end

      def cursor_for(model)
        {
          updated_at: aggregation[updated_at_column(model)],
          id: aggregation[id_column(model)]
        }.compact
      end

      def updated_at_column(model)
        "last_#{mode}_#{model.table_name}_updated_at"
      end

      def id_column(model)
        "last_#{mode}_#{model.table_name}_id"
      end

      def runtime_column
        "#{mode}_runtimes_in_seconds"
      end

      def processed_records_column
        "#{mode}_processed_records"
      end
    end
  end
end
