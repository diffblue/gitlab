# frozen_string_literal: true

class MigrateJobArtifactRegistry < Gitlab::Database::Migration[1.0]
  MIGRATION = 'MigrateJobArtifactRegistryToSsf'
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 5_000

  disable_ddl_transaction!

  class JobArtifactRegistry < Geo::TrackingBase
    include EachBatch

    self.table_name = 'job_artifact_registry'
  end

  def up
    queue_background_migration_jobs_by_range_at_intervals(JobArtifactRegistry, MIGRATION, DELAY_INTERVAL, batch_size: BATCH_SIZE)
  end

  def down
    # no-op
  end

  private

  # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/353644#note_944460720
  # This works by conicidence since:
  # 1. There's no tracking database nor JobCoordinator for Geo
  # 2. We do not use `track_jobs: true` so we do not store jobs in DB
  # 3. If we would use `track_jobs: true` it would break since the `ActiveRecord::Base` is `:geo`
  #    and there are not associated tables for `background_migrations_*` in this database
  # 4. As result the `requeue_background_migration_jobs_by_range_at_intervals` and `finalize_background_migration`
  #    will not work since there's no associated data in database
  # 5. This is mischeduled using `BackgroundMigrationWorker` which sets `SharedModel` to `:main`
  def coordinator_for_tracking_database
    Gitlab::BackgroundMigration::JobCoordinator.for_tracking_database('main')
  end
end
