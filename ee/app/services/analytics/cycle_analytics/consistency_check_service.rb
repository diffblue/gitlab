# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    class ConsistencyCheckService
      include Validations

      BATCH_LIMIT = 1000

      def initialize(group:, event_model:)
        @group = group
        @event_model = event_model
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def execute(runtime_limiter: RuntimeLimiter.new(Analytics::CycleAnalytics::ConsistencyWorker::MAX_RUNTIME), cursor_data: {})
        @runtime_limiter = runtime_limiter

        error_response = validate
        return error_response if error_response

        stage_event_hash_ids(cursor_data).each do |stage_event_hash_id|
          cursor = cursor_from_data(cursor_data)
          scope = event_model.where(stage_event_hash_id: stage_event_hash_id).where.not(end_event_timestamp: nil).order_by_end_event(:asc)

          iterator(scope, cursor).each_batch(of: BATCH_LIMIT) do |relation|
            if @runtime_limiter.over_time?
              payload = {
                cursor: cursor,
                stage_event_hash_id: stage_event_hash_id,
                model: model
              }
              # rubocop: disable Cop/AvoidReturnFromBlocks
              return success(:limit_reached, payload)
              # rubocop: enable Cop/AvoidReturnFromBlocks
            end

            ids = relation.pluck(event_model.issuable_id_column)

            next if ids.empty?

            cursor = cursor_for_record(relation.last, scope)

            id_list = Arel::Nodes::ValuesList.new(ids.map { |id| [id] })

            # Check if the referenced issues or merge requests still exist
            inconsistent_id_list = model.connection.select_values <<~SQL
            SELECT ids.stage_event_issuable_id
            FROM ((#{id_list.to_sql})) AS ids(stage_event_issuable_id)
            WHERE
            NOT EXISTS (#{model.select('1').where('id = ids.stage_event_issuable_id').to_sql})
            SQL

            next if inconsistent_id_list.empty?

            event_model.where(stage_event_hash_id: stage_event_hash_id, event_model.issuable_id_column => inconsistent_id_list).delete_all
          end
        end

        success(:group_processed)
      end
      # rubocop: enable CodeReuse/ActiveRecord

      private

      attr_reader :group, :event_model

      # rubocop: disable CodeReuse/ActiveRecord
      def iterator(scope, cursor)
        opts = {
          in_operator_optimization_options: {
            array_scope: group.self_and_descendant_ids,
            array_mapping_scope: -> (id_expression) { event_model.where(event_model.arel_table[:group_id].eq(id_expression)) }
          }
        }

        Gitlab::Pagination::Keyset::Iterator.new(scope: scope, cursor: cursor, **opts)
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def cursor_from_data(cursor_data)
        if model == ::MergeRequest
          cursor_data[:merge_requests_cursor] || {}
        elsif model == ::Issue
          cursor_data[:issues_cursor] || {}
        else
          raise "invalid model #{model}"
        end
      end

      def stage_event_hash_id_from_cursor_data(cursor_data)
        if model == ::MergeRequest
          cursor_data[:merge_requests_stage_event_hash_id]
        elsif model == ::Issue
          cursor_data[:issues_stage_event_hash_id]
        else
          raise "invalid model #{model}"
        end
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def cursor_for_record(record, scope)
        order = Gitlab::Pagination::Keyset::Order.extract_keyset_order_object(scope)
        order.cursor_attributes_for_node(record)
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def stage_event_hash_ids(cursor_data)
        last_stage_event_hash_id = stage_event_hash_id_from_cursor_data(cursor_data)

        @stage_event_hash_ids ||= ::Gitlab::Analytics::CycleAnalytics::DistinctStageLoader
          .new(group: group)
          .stages
          .select { |stage| stage.start_event.object_type == model }
          .map(&:stage_event_hash_id)
          .sort
          .drop_while { |id| last_stage_event_hash_id && id < last_stage_event_hash_id }
      end

      def model
        event_model.issuable_model
      end
    end
  end
end
