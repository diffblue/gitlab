# frozen_string_literal: true

module Geo
  class DesignRepositorySyncWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :always
    include GeoQueue
    include Gitlab::Geo::LogHelpers

    sidekiq_options retry: 3, dead: false

    sidekiq_retry_in { |count| 30 * count }

    sidekiq_retries_exhausted do |msg, _|
      Sidekiq.logger.warn "Failed #{msg['class']} with #{msg['args']}: #{msg['error_message']}"
    end

    def perform(project_id)
      registry = Geo::DesignRegistry.find_or_initialize_by(project_id: project_id) # rubocop: disable CodeReuse/ActiveRecord
      project = registry.project

      if project.nil?
        log_error("Couldn't find project, skipping syncing", project_id: project_id)
        return
      end

      Geo::DesignRepositorySyncService.new(registry.project).execute
    end
  end
end
