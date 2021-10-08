# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Backfills the `namespaces.type` column, replacing any
    # instances of `NULL` with `User`
    class BackfillUserNamespace
      include Gitlab::Database::DynamicModelHelpers

      def perform(start_id, end_id, batch_table, batch_column, sub_batch_size)
        parent_batch_relation = relation_scoped_to_range(batch_table, batch_column, start_id, end_id)

        parent_batch_relation.each_batch(column: batch_column, of: sub_batch_size) do |sub_batch|
          batch_metrics.time_operation(:update_all) do
            sub_batch.update_all(type: 'User')
          end

          pause_ms = 0 if pause_ms < 0
          sleep(pause_ms * 0.001)
        end

        # ActiveRecord::Base.connection.execute(<<~SQL)
        #   UPDATE namespaces SET type = 'User'
        #   WHERE id BETWEEN #{start_id} AND #{end_id}
        #     AND type IS NULL
        # SQL
      end

      def batch_metrics
        @batch_metrics ||= Gitlab::Database::BackgroundMigration::BatchMetrics.new
      end

      private

      def connection
        ActiveRecord::Base.connection
      end

      def relation_scoped_to_range(source_table, source_key_column, start_id, stop_id)
        define_batchable_model(source_table)
          .where(source_key_column => start_id..stop_id)
          .where(type: nil)
      end
    end
  end
end
