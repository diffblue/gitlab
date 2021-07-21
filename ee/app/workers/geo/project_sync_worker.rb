# frozen_string_literal: true

module Geo
  class ProjectSyncWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :always
    include GeoQueue
    include Gitlab::Geo::LogHelpers

    sidekiq_options retry: 3, dead: false

    sidekiq_retry_in { |count| 30 * count }

    sidekiq_retries_exhausted do |msg, _|
      Sidekiq.logger.warn "Failed #{msg['class']} with #{msg['args']}: #{msg['error_message']}"
    end

    loggable_arguments 1

    # rubocop: disable CodeReuse/ActiveRecord
    def perform(project_id, options = {})
      options.symbolize_keys!

      registry = Geo::ProjectRegistry.find_or_initialize_by(project_id: project_id)
      project = registry.project

      if project.nil?
        log_error("Couldn't find project, skipping syncing", project_id: project_id)
        return
      end

      shard_name = project.repository_storage
      unless Gitlab::ShardHealthCache.healthy_shard?(shard_name)
        log_error("Project shard '#{shard_name}' is unhealthy, skipping syncing", project_id: project_id)
        return
      end

      sync_repository(registry, options)
      sync_wiki(registry, options)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def sync_repository(registry, options)
      return unless options[:sync_repository] && registry.resync_repository?

      Geo::RepositorySyncService.new(registry.project).execute
    end

    def sync_wiki(registry, options)
      return unless options[:sync_wiki] && registry.resync_wiki?

      Geo::WikiSyncService.new(registry.project).execute
    end
  end
end
