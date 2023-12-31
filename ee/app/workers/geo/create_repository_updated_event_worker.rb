# frozen_string_literal: true

module Geo
  class CreateRepositoryUpdatedEventWorker
    include ApplicationWorker
    include Gitlab::EventStore::Subscriber
    include ::GeoQueue

    data_consistency :always

    idempotent!

    def handle_event(event)
      Project.find_by_id(event.data[:project_id]).try do |project|
        if ::Geo::ProjectRepositoryReplicator.enabled?
          project.geo_handle_after_update
        else
          ::Geo::RepositoryUpdatedService.new(project.repository).execute
        end
      end
    end
  end
end
