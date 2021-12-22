# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    module BatchingStrategies
      # Generic batching class for use with a BatchedBackgroundMigration.
      # Batches over the given table and column combination, returning the MIN() and MAX()
      # values for the next batch as an array.
      #
      # If no more batches exist in the table, returns nil.
      class PrimaryKeyBatchingStrategy
        include Gitlab::Database::DynamicModelHelpers

        def initialize(batched_migration)
          @batched_migration = batched_migration
        end

        # Finds and returns the next batch in the table.
        #
        # batch_min_value - The minimum value which the next batch will start at
        # batch_size - The size of the next batch
        def next_batch(batch_min_value:, batch_size:)
          model_class = define_batchable_model(batched_migration.table_name)

          quoted_column_name = model_class.connection.quote_column_name(batched_migration.column_name)
          relation = model_class.where("#{quoted_column_name} >= ?", batch_min_value)
          next_batch_bounds = nil

          relation.each_batch(of: batch_size, column: batched_migration.column_name) do |batch| # rubocop:disable Lint/UnreachableLoop
            next_batch_bounds = batch.pluck(Arel.sql("MIN(#{quoted_column_name}), MAX(#{quoted_column_name})")).first

            break
          end

          next_batch_bounds
        end

        private

        attr_reader :batched_migration
      end
    end
  end
end
