# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      module StageEvents
        class FirstAssignedAt < StageEvent
          def column_list
            [event_model.arel_table[:created_at]]
          end

          # rubocop: disable CodeReuse/ActiveRecord
          # This method is not used on production since we're using the aggregated backend.
          # It's implemented so we respect the interface of StageEvent.
          override :apply_query_customization
          def apply_query_customization(query)
            query
              .joins("INNER JOIN LATERAL (#{subquery.to_sql}) #{event_model.quoted_table_name} ON TRUE")
          end

          # This method is not used on production since we're using the aggregated backend.
          # It's implemented so we respect the interface of StageEvent.
          override :apply_negated_query_customization
          def apply_negated_query_customization(query)
            query.where('NOT EXISTS (?)', subquery)
          end

          override :include_in
          def include_in(query)
            query
              .joins("LEFT JOIN LATERAL (#{subquery.to_sql}) #{event_model.quoted_table_name} ON TRUE")
          end

          def subquery
            event_model
              .where(object_type.arel_table[:id].eq(event_model.arel_table[event_model.issuable_id_column]))
              .where(action: :add)
              .order(:created_at, :id)
              .limit(1)
          end
          # rubocop: enable CodeReuse/ActiveRecord
        end
      end
    end
  end
end
