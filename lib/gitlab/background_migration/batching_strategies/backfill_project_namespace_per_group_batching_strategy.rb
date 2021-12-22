# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    module BatchingStrategies
      # Batching class to use for back-filling project namespaces for a single group.
      # Batches over the projects table and id column combination, scoped to a given group returning the MIN() and MAX()
      # values for the next batch as an array.
      #
      # If no more batches exist in the table, returns nil.
      class BackfillProjectNamespacePerGroupBatchingStrategy < PrimaryKeyBatchingStrategy
        # Finds and returns the next batch in the table.
        #
        # batch_min_value - The minimum value which the next batch will start at
        # batch_size - The size of the next batch
        def next_batch(batch_min_value:, batch_size:)
          next_batch_bounds = nil
          model_class = ::Gitlab::BackgroundMigration::ProjectNamespaces::Models::Project
          quoted_column_name = model_class.connection.quote_column_name(batched_migration.column_name)
          projects_table = model_class.arel_table
          hierarchy_cte_sql = Arel::Nodes::SqlLiteral.new(::Gitlab::BackgroundMigration::ProjectNamespaces::BackfillProjectNamespaces.hierarchy_cte(batched_migration.job_arguments.first))
          relation = model_class.where(projects_table[:namespace_id].in(hierarchy_cte_sql)).where("#{quoted_column_name} >= ?", batch_min_value)

          relation.each_batch(of: batch_size, column: batched_migration.column_name) do |batch| # rubocop:disable Lint/UnreachableLoop
            next_batch_bounds = batch.pluck(Arel.sql("MIN(#{quoted_column_name}), MAX(#{quoted_column_name})")).first

            break
          end

          next_batch_bounds
        end
      end
    end
  end
end
