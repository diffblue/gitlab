# frozen_string_literal: true

class MigrateSidekiqJobs < Gitlab::Database::Migration[2.0]
  def up
    mappings = Gitlab::SidekiqConfig.worker_queue_mappings
    logger = ::Gitlab::BackgroundMigration::Logger.build
    Gitlab::SidekiqMigrateJobs.new(mappings, logger: logger).migrate_queues
  end

  def down
    # no-op
  end
end
