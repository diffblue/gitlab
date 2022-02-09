# frozen_string_literal: true

class BackfillIntegrationsEnableSslVerification < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  MIGRATION = 'BackfillIntegrationsEnableSslVerification'
  INTERVAL = 5.minutes
  BATCH_SIZE = 1_000

  def up
    queue_background_migration_jobs_by_range_at_intervals(
      Gitlab::BackgroundMigration::BackfillIntegrationsEnableSslVerification::Integration.affected,
      MIGRATION,
      INTERVAL,
      batch_size: BATCH_SIZE,
      track_jobs: true
    )
  end

  def down
  end
end
