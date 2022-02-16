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
end
