# frozen_string_literal: true

module Geo
  class HashedStorageMigrationWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3
    include GeoQueue

    loggable_arguments 1, 2, 2

    def perform(project_id, old_disk_path, new_disk_path, old_storage_version)
      Geo::HashedStorageMigrationService.new(
        project_id,
        old_disk_path: old_disk_path,
        new_disk_path: new_disk_path,
        old_storage_version: old_storage_version
      ).execute
    end
  end
end
