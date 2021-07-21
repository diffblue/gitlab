# frozen_string_literal: true

module Geo
  module Secondary
    # Iterates over syncable records and creates the corresponding registry
    # records which are missing. Then, the workers that actually schedule the
    # sync work only have to query the registry table for never-synced records.
    class RegistryConsistencyWorker
      include ApplicationWorker

      data_consistency :always

      sidekiq_options retry: 3
      prepend Reenqueuer
      include ::Gitlab::Geo::LogHelpers

      # There is no relevant user/project/namespace/caller context for this worker
      include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

      feature_category :geo_replication
      tags :exclude_from_gitlab_com

      REGISTRY_CLASSES = [
        Geo::ContainerRepositoryRegistry,
        Geo::DesignRegistry,
        Geo::JobArtifactRegistry,
        Geo::LfsObjectRegistry,
        Geo::MergeRequestDiffRegistry,
        Geo::PackageFileRegistry,
        Geo::PipelineArtifactRegistry,
        Geo::ProjectRegistry,
        Geo::TerraformStateVersionRegistry,
        Geo::UploadRegistry,
        Geo::SnippetRepositoryRegistry,
        Geo::GroupWikiRepositoryRegistry
      ].freeze

      BATCH_SIZE = 10000

      idempotent!

      # @return [Boolean] true if at least 1 registry was created, else false
      def perform
        return false unless registry_classes.any? # May as well remove this check after one registry no longer feature flags this
        return false unless Gitlab::Geo.secondary?

        backfill
      rescue StandardError => e
        log_error("Error while backfilling all", e)

        raise
      end

      def lease_timeout
        [registry_classes.size, 1].max * 1.minute
      end

      private

      def backfill
        log_info("Backfill registries", registry_classes: registry_classes.map(&:to_s), batch_size: BATCH_SIZE)

        registry_classes.map { |registry_class| registry_service(registry_class).execute }.any?
      end

      def registry_service(registry_class)
        Geo::RegistryConsistencyService.new(registry_class, batch_size: BATCH_SIZE)
      end

      def registry_classes
        @registry_classes ||= REGISTRY_CLASSES.select do |registry_class|
          # Defaults on. This check gives registry classes the opportunity to
          # disable this worker, e.g. with a feature flag.
          !registry_class.respond_to?(:registry_consistency_worker_enabled?) ||
            registry_class.registry_consistency_worker_enabled?
        end
      end
    end
  end
end
