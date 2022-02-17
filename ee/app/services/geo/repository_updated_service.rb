# frozen_string_literal: true

# This service is deprecated. Don't add new resources to here.
# Use the new Self-Service Framework instead.
module Geo
  class RepositoryUpdatedService
    include ::Gitlab::Geo::ProjectLogHelpers

    RepositoryUpdateError = Class.new(StandardError)

    def initialize(repository, params = {})
      @project    = repository.project
      @repository = repository
      @params     = params
      @refs       = params.fetch(:refs, [])
      @changes    = params.fetch(:changes, [])
      @source     = Geo::RepositoryUpdatedEvent.source_for(repository)
    end

    def execute
      return false unless Gitlab::Geo.primary?

      reset_repository_checksum!
      create_repository_updated_event!

      true
    end

    private

    attr_reader :project, :repository, :refs, :changes, :source

    delegate :repository_state, to: :project

    def create_repository_updated_event!
      return unless repository.exists?

      Geo::RepositoryUpdatedEventStore.new(
        project, refs: refs, changes: changes, source: source
      ).create!
    end

    def design?
      source == Geo::RepositoryUpdatedEvent::DESIGN
    end

    def reset_repository_checksum!
      # We don't yet support verification for Design repositories
      return if design?
      return if repository_state.nil?

      repository_state.update!(
        "#{repository_checksum_column}" => nil,
        "#{repository_failure_column}" => nil,
        "#{repository_retry_at_column}" => nil,
        "#{repository_retry_count_column}" => nil
      )
    rescue StandardError => e
      log_error('Cannot reset repository checksum', e)
      raise RepositoryUpdateError, "Cannot reset repository checksum: #{e}"
    end

    def repository_checksum_column
      "#{repository_type}_verification_checksum"
    end

    def repository_failure_column
      "last_#{repository_type}_verification_failure"
    end

    def repository_retry_at_column
      "#{repository_type}_retry_at"
    end

    def repository_retry_count_column
      "#{repository_type}_retry_count"
    end

    def repository_type
      @repository_type ||= Geo::RepositoryUpdatedEvent.sources.key(source)
    end
  end
end
