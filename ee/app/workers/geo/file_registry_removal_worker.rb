# frozen_string_literal: true

module Geo
  class FileRegistryRemovalWorker
    include ApplicationWorker

    # Do not execute (in fact, don't even enqueue) another instance of this Worker with the same args
    deduplicate :until_executed, including_scheduled: true
    idempotent!

    data_consistency :always

    sidekiq_options retry: 3
    include GeoQueue
    include ::Gitlab::Geo::LogHelpers

    loggable_arguments 0, 2

    # This worker not only works for Self-Service Framework, it's also backward compatible
    # "object_type" is "replicable_name" and "object_db_id" is "replicable_id".
    def perform(replicable_name, replicable_id, file_path = nil)
      log_info('Executing Geo::FileRegistryRemovalService', id: replicable_id, type: replicable_name, file_path: file_path)

      ::Geo::FileRegistryRemovalService.new(replicable_name, replicable_id, file_path).execute
    end
  end
end
