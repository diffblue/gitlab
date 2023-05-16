# frozen_string_literal: true

module Geo
  class ContainerRepositoryReplicator < Gitlab::Geo::Replicator
    include ::Geo::VerifiableReplicator
    include Gitlab::Geo::LogHelpers

    extend ::Gitlab::Utils::Override
    extend ActiveSupport::Concern

    event :created
    event :updated
    event :deleted

    class << self
      extend ::Gitlab::Utils::Override

      override :verification_feature_flag_enabled?
      def verification_feature_flag_enabled?
        true
      end

      def model
        ::ContainerRepository
      end

      # ContainerRepository replication is a bit different in a way that it's not enough
      # to check if the feature flag is enabled we also need to check if
      # it's enabled in the config file Gitlab.config.geo.registry_replication.enabled
      #
      # rubocop:disable Style/IfUnlessModifier
      def enabled?
        if ::Gitlab::Geo.secondary?
          return super && Geo::ContainerRepositoryRegistry.replication_enabled?
        end

        super
      end
      # rubocop:enable Style/IfUnlessModifier

      def sync_timeout
        ::Geo::ContainerRepositorySyncService::LEASE_TIMEOUT
      end

      def data_type
        'container_repository'
      end

      def data_type_title
        _('Container Repository')
      end
    end

    # Called by Gitlab::Geo::Replicator#consume
    def consume_event_updated(**params)
      resync
    end

    # Called by Gitlab::Geo::Replicator#consume
    def consume_event_created(...)
      consume_event_updated(...)
    end

    # Called by Gitlab::Geo::Replicator#consume
    def consume_event_deleted(**params)
      replicate_destroy(params)
    end

    def resync
      return unless in_replicables_for_current_secondary?

      Geo::ContainerRepositorySyncService.new(model_record).execute
    end

    override :deleted_params
    def deleted_params
      event_params.merge(path: model_record.path)
    end

    def replicate_destroy(event_data)
      ::Geo::ContainerRepositoryRegistryRemovalService.new(
        model_record_id,
        event_data[:path]
      ).execute
    end

    def enqueue_sync
      Geo::EventWorker.perform_async(replicable_name, 'updated', { model_record_id: model_record.id })
    end

    # Returns a checksum of the tag list
    #
    # @return [String] SHA256 hash of the repository tag list
    def calculate_checksum
      model_record.tag_list_digest
    end

    def checksummable?
      true
    end

    def immutable?
      false
    end
  end
end
