# frozen_string_literal: true

class GeoRepositoryDestroyWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3
  include GeoQueue
  include ::Gitlab::Geo::LogHelpers

  loggable_arguments 1, 2, 3

  def perform(id, name = nil, disk_path = nil, storage_name = nil)
    log_info('Executing Geo::RepositoryDestroyService', id: id, name: name, disk_path: disk_path, storage_name: storage_name)

    Geo::RepositoryDestroyService.new(id, name, disk_path, storage_name).execute
  end
end
