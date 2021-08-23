# frozen_string_literal: true

begin
  Gitlab::Database::Partitioning.sync_partitions unless ENV['DISABLE_POSTGRES_PARTITION_CREATION_ON_STARTUP']
rescue ActiveRecord::ActiveRecordError, PG::Error
  # ignore - happens when Rake tasks yet have to create a database, e.g. for testing
end
