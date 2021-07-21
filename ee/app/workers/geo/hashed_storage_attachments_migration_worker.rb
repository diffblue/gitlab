# frozen_string_literal: true

module Geo
  class HashedStorageAttachmentsMigrationWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3
    include GeoQueue

    loggable_arguments 1, 2

    def perform(project_id, old_attachments_path, new_attachments_path)
      Geo::HashedStorageAttachmentsMigrationService.new(
        project_id,
        old_attachments_path: old_attachments_path,
        new_attachments_path: new_attachments_path
      ).execute
    end
  end
end
