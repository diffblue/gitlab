# frozen_string_literal: true

module Analytics
  module ValueStreamDashboard
    class TopLevelGroupCounterService
      UNIQUE_BY_CLAUSE = %i[namespace_id metric recorded_at count id].freeze
      INSERT_BATCH_SIZE = 100
      COUNT_BATCH_SIZE = 5000

      # rubocop: disable CodeReuse/ActiveRecord
      GROUP_SELECT_SCOPE = ->(scope) { scope.select(:id) }
      PROJECT_SELECT_SCOPE = ->(scope) {
        scope.joins(:project).select(:id, Project.arel_table[:id].as('tmp_project_id'))
      }

      # - metric: metric value for the metrics enum in Analytics::ValueStreamDashboard::Count
      # - namespace_class: class to use for iterating (EachBatch) over specific namespaces (Group or ProjectNamespace)
      # - inner_namespace_query: transform the yielded query provided by the namespace_class
      #
      #  Example:
      #
      #  Consider the following configuration:
      #  ```
      #    namespace_class = Group
      #    inner_namespace_query = ->(scope) { scope.select(:id) }
      #
      #    # the two configuration option will be used in EachBatch:
      #
      #    namespace_class.where("traversal_ids[1] = ?", 1).each_batch do |relation|
      #      # the `inner_namespace_query` lambda will modify the yielded relation, result:
      #      namespaces = relation.select(:id)
      #    end
      #  ```
      #
      # - count_scope: use this scope when counting items in batches
      # - count_batching_column: batch countable items by this column
      COUNTS_TO_COLLECT = {
        projects: {
          metric: ::Analytics::ValueStreamDashboard::Count.metrics[:projects],
          namespace_class: Group,
          inner_namespace_query: GROUP_SELECT_SCOPE,
          count_scope: Project.method(:in_namespace),
          count_batching_column: :id
        }.freeze,
        issues: {
          metric: ::Analytics::ValueStreamDashboard::Count.metrics[:issues],
          namespace_class: Namespaces::ProjectNamespace,
          inner_namespace_query: PROJECT_SELECT_SCOPE,
          count_scope: ->(namespace) { Issue.in_projects(namespace.tmp_project_id) },
          count_batching_column: :iid
        }.freeze,
        groups: {
          metric: ::Analytics::ValueStreamDashboard::Count.metrics[:groups],
          namespace_class: Group,
          inner_namespace_query: GROUP_SELECT_SCOPE,
          count_batching_column: :id,
          count_scope: ->(namespace) { Group.where(parent_id: namespace.id) }
        }.freeze,
        merge_requests: {
          metric: ::Analytics::ValueStreamDashboard::Count.metrics[:merge_requests],
          namespace_class: Namespaces::ProjectNamespace,
          inner_namespace_query: PROJECT_SELECT_SCOPE,
          count_batching_column: :iid,
          count_scope: ->(namespace) { MergeRequest.where(target_project_id: namespace.tmp_project_id) }
        }.freeze,
        pipelines: {
          metric: ::Analytics::ValueStreamDashboard::Count.metrics[:pipelines],
          namespace_class: Namespaces::ProjectNamespace,
          inner_namespace_query: PROJECT_SELECT_SCOPE,
          count_batching_column: :id,
          count_scope: ->(namespace) { Ci::Pipeline.where(project_id: namespace.tmp_project_id) }
        }.freeze
      }.freeze
      # rubocop: enable CodeReuse/ActiveRecord

      def initialize(aggregation:, runtime_limiter:, cursor:)
        @aggregation = aggregation
        @runtime_limiter = runtime_limiter
        @cursor = cursor
        @counts_to_insert = []
      end

      def execute
        metrics_to_count.each do |countable_config|
          ensure_cursor(countable_config: countable_config)

          while namespace = cursor.next # rubocop: disable Lint/AssignmentInCondition
            break if runtime_limiter.over_time?

            last_count, last_value = batch_count_items(namespace, countable_config)

            # last_value is only provided when there are more items to count but the batch counting
            # was stopped due to time limit.
            if !last_value
              cursor.update(last_count: nil, last_value: nil)
              @counts_to_insert << build_count_record(last_count, namespace, countable_config)
            else
              cursor.update(last_count: last_count, last_value: last_value)
              break
            end
          end

          break if namespace # counting interrupted in the middle.

          @cursor = nil
        end

        finalize
      end

      def self.load_cursor(raw_cursor:, countable_config: nil)
        raw_cursor[:metric] ||= Analytics::ValueStreamDashboard::Count.metrics[:projects]
        countable_config ||= COUNTS_TO_COLLECT.values.detect { |config| config[:metric] == raw_cursor[:metric] }

        Gitlab::Analytics::ValueStreamDashboard::NamespaceCursor.new(
          namespace_class: countable_config[:namespace_class],
          inner_namespace_query: countable_config[:inner_namespace_query],
          cursor_data: raw_cursor.merge({ metric: countable_config[:metric] })
        )
      end

      private

      attr_reader :raw_cursor, :aggregation, :cursor, :runtime_limiter

      def ensure_cursor(countable_config:)
        @cursor ||= self.class.load_cursor(raw_cursor: { top_level_namespace_id: aggregation.id },
          countable_config: countable_config)
      end

      def metrics_to_count
        return COUNTS_TO_COLLECT.values unless cursor

        # Skip count configs before the provided metric
        COUNTS_TO_COLLECT.values.drop_while { |v| v[:metric] != cursor[:metric] }
      end

      def batch_count_items(namespace, countable_config)
        arguments = {
          of: COUNT_BATCH_SIZE,
          column: countable_config[:count_batching_column],
          last_count: cursor[:last_count] || 0,
          last_value: cursor[:last_value]
        }

        countable_config[:count_scope].call(namespace).each_batch_count(**arguments) do
          runtime_limiter.over_time? # Stop the batch-counting when over time
        end
      end

      def build_count_record(last_count, namespace, _countable_config)
        {
          count: last_count,
          namespace_id: namespace.id,
          recorded_at: Time.current,
          metric: cursor[:metric]
        }
      end

      def finalize
        insert_collected_counts

        if runtime_limiter.was_over_time?
          ServiceResponse.success(payload: { cursor: cursor, result: :interrupted })
        else
          aggregation.update!(last_run_at: Time.current)
          ServiceResponse.success(payload: { cursor: cursor, result: :finished })
        end
      end

      def insert_collected_counts
        @counts_to_insert.each_slice(INSERT_BATCH_SIZE) do |slice|
          Analytics::ValueStreamDashboard::Count.insert_all(slice, unique_by: UNIQUE_BY_CLAUSE)
        end
      end
    end
  end
end
