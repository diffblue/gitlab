# frozen_string_literal: true

class BackfillProjectNamespacesForGroup < Gitlab::Database::Migration[1.0]
  MIGRATION = 'ProjectNamespaces::BackfillProjectNamespaces'
  DELAY_INTERVAL = 2.minutes
  GROUP_ID = 9970 # pick a test group id here

  disable_ddl_transaction!

  def up
    # return unless Gitlab.com?

    projects_table = ::Gitlab::BackgroundMigration::ProjectNamespaces::Models::Project.arel_table
    hierarchy_cte_sql = Arel::Nodes::SqlLiteral.new(::Gitlab::BackgroundMigration::ProjectNamespaces::BackfillProjectNamespaces.hierarchy_cte(GROUP_ID))
    group_projects = ::Gitlab::BackgroundMigration::ProjectNamespaces::Models::Project.where(projects_table[:namespace_id].in(hierarchy_cte_sql))

    min_id = group_projects&.minimum(:id)
    max_id = group_projects&.maximum(:id)

    return if min_id.blank? || max_id.blank?

    migration = queue_batched_background_migration(
      MIGRATION,
      :projects,
      :id,
      GROUP_ID,
      'up',
      job_interval: DELAY_INTERVAL,
      batch_min_value: min_id,
      batch_max_value: max_id,
      sub_batch_size: 50
    )

    Gitlab::Database::BackgroundMigration::BatchedMigrationRunner.new.run_entire_migration(migration)
  end

  def down
    # return unless Gitlab.com?

    Gitlab::Database::BackgroundMigration::BatchedMigration
      .for_configuration(MIGRATION, :projects, :id, [GROUP_ID, 'up']).delete_all
  end
end
