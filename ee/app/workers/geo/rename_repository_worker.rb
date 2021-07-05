# frozen_string_literal: true

module Geo
  class RenameRepositoryWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3
    include GeoQueue

    loggable_arguments 1, 2

    def perform(project_id, old_disk_path, new_disk_path)
      Geo::RenameRepositoryService.new(project_id, old_disk_path, new_disk_path).execute
    end
  end
end
