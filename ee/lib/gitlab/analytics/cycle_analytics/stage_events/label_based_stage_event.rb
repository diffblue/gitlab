# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      module StageEvents
        # Represents an event that is related to label creation or removal, this model requires a label provided by the user
        class LabelBasedStageEvent < StageEvent
          include ActiveRecord::ConnectionAdapters::Quoting

          def label
            params.fetch(:label)
          end

          def label_id
            label.id
          end

          def self.label_based?
            true
          end

          def hash_code
            Digest::SHA256.hexdigest("#{self.class.identifier}-#{label_id}")
          end

          def column_list
            [Arel.sql("#{join_expression_name}.created_at")]
          end

          # rubocop: disable CodeReuse/ActiveRecord
          def apply_query_customization(query)
            query
              .from(Arel::Nodes::Grouping.new(Arel.sql(object_type.all.to_sql)).as(object_type.table_name)) # This is needed for the LATERAL JOIN: FROM (SELECT * FROM table) as table
              .joins("INNER JOIN LATERAL (#{subquery.to_sql}) #{join_expression_name} ON TRUE")
          end
          # rubocop: enable CodeReuse/ActiveRecord

          # rubocop: disable CodeReuse/ActiveRecord
          def apply_negated_query_customization(query)
            query.where('NOT EXISTS (?)', subquery)
          end
          # rubocop: enable CodeReuse/ActiveRecord

          private

          def resource_label_events_table
            ResourceLabelEvent.arel_table
          end

          # Labels can be assigned and unassigned multiple times, we need a way to pick only one record from `resource_label_events` table.
          # Consider the following example:
          #
          # | id | action | label_id | issue_id | created_at |
          # | -- | ------ | -------- | -------- | ---------- |
          # | 1  | add    | 1        | 10       | 2010-01-01 |
          # | 2  | remove | 1        | 10       | 2010-02-01 |
          # | 3  | add    | 1        | 10       | 2015-01-01 |
          # | 4  | remove | 1        | 10       | 2015-02-01 |
          #
          # In this example a label (id: 1) has been assigned and unassigned twice on the same Issue.
          #
          # - IssueLabelAdded event: find the first assignment (add, id = 1)
          # - IssueLabelRemoved event: find the latest unassignment (remove, id = 4)
          #
          #  Arguments:
          #    foreign_key: :issue_id or :merge_request_id (based on resource_label_events table)
          #    label: label model,
          #    action: :add or :remove
          #    order: :asc or :desc

          # rubocop: disable CodeReuse/ActiveRecord
          def resource_label_events_with_subquery(foreign_key, label, action, order)
            ResourceLabelEvent
              .select(:created_at)
              .where(action: action)
              .where(label_id: label.id)
              .where(ResourceLabelEvent.arel_table[foreign_key].eq(object_type.arel_table[:id]))
              .order(order_expression(order))
              .limit(1)
          end
          # rubocop: enable CodeReuse/ActiveRecord

          # The same join expression could be used multiple times in the same query, to avoid conflicts, we're adding random hex string as suffix.
          def join_expression_name
            @join_expression_name ||= quote_table_name("#{self.class.to_s.demodulize.underscore}_#{SecureRandom.hex(5)}")
          end

          def order_expression(order)
            case order
            when :asc
              resource_label_events_table[:created_at].asc
            when :desc
              resource_label_events_table[:created_at].desc
            else
              raise "unsupported order option: #{order}"
            end
          end
        end
      end
    end
  end
end
