# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      module Aggregated
        class DataForDurationChart
          include StageQueryHelpers

          def initialize(stage:, params:, query:)
            @stage = stage
            @params = params
            @query = query
          end

          # rubocop: disable CodeReuse/ActiveRecord
          def average_by_day
            @query
              .group(date_expression)
              .select(date_expression.as('date'), duration_in_seconds.average.as('average_duration_in_seconds'))
          end
          # rubocop: enable CodeReuse/ActiveRecord

          private

          attr_reader :stage, :query, :params

          def date_expression
            Arel::Nodes::NamedFunction.new('DATE', [query.model.arel_table[:end_event_timestamp]])
          end
        end
      end
    end
  end
end
