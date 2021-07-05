# frozen_string_literal: true

module Geo
  class ContainerRepositorySyncWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :always
    include GeoQueue
    include Gitlab::Geo::LogHelpers

    sidekiq_options retry: 3, dead: false

    sidekiq_retry_in { |count| 30 * count }

    sidekiq_retries_exhausted do |msg, _|
      Sidekiq.logger.warn "Failed #{msg['class']} with #{msg['args']}: #{msg['error_message']}"
    end

    attr_reader :repository

    def perform(id)
      @repository = ContainerRepository.find_by_id(id)

      if repository.nil?
        log_error("Couldn't find container repository, skipping syncing", container_repository_id: id)
        return
      end

      Geo::ContainerRepositorySyncService.new(repository).execute
    end
  end
end
