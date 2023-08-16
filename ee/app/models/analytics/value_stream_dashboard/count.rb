# frozen_string_literal: true

module Analytics
  module ValueStreamDashboard
    class Count < ApplicationRecord
      include PartitionedTable

      self.table_name = :value_stream_dashboard_counts
      self.primary_key = :id

      partitioned_by :recorded_at, strategy: :monthly

      belongs_to :namespace

      validates :namespace_id, :count, :metric, :recorded_at, presence: true

      enum metric: { projects: 1, issues: 2, groups: 3, merge_requests: 4, pipelines: 5 }

      scope :latest_first_order, -> { order(recorded_at: :desc, id: :desc) }
      scope :for_period, ->(metric, from, to) {
        where(metric: metric)
          .where(arel_table[:recorded_at].gteq(from))
          .where(arel_table[:recorded_at].lteq(to))
      }

      def self.aggregate_for_period(group, metric, from, to)
        namespace_query = "(#{descendant_namespace_ids_for(group, metric).to_sql}) AS ids(id)"

        lateral_query = for_period(metric, from, to)
          .where('ids.id = value_stream_dashboard_counts.namespace_id')
          .latest_first_order
          .select(:count, :recorded_at)
          .limit(1)
          .to_sql

        from("#{namespace_query}, LATERAL (#{lateral_query}) AS counts")
          .limit(1)
          .pick(Arel.sql("SUM(counts.count) OVER (), MAX(counts.recorded_at) OVER ()"))
      end

      def self.descendant_namespace_ids_for(group, metric)
        metric_namespace_class = Analytics::ValueStreamDashboard::TopLevelGroupCounterService::COUNTS_TO_COLLECT
          .fetch(metric)
          .fetch(:namespace_class)

        if metric_namespace_class == Group
          group.self_and_descendant_ids
        elsif metric_namespace_class == Namespaces::ProjectNamespace
          group.all_projects.select(:project_namespace_id)
        else
          Group.none
        end
      end
    end
  end
end
