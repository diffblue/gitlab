# frozen_string_literal: true

module Geo
  class ContainerRepositoryReplicator < Gitlab::Geo::Replicator
    include Gitlab::Geo::LogHelpers

    extend ActiveSupport::Concern

    event :created
    event :updated

    class << self
      extend ::Gitlab::Utils::Override

      override :verification_feature_flag_enabled?
      def verification_feature_flag_enabled?
        false
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
        'repository'
      end

      def data_type_title
        _('Container Repository')
      end
    end

    # Called by Gitlab::Geo::Replicator#consume
    def consume_event_created(**params)
      consume_event_updated(params)
    end

    # Called by Gitlab::Geo::Replicator#consume
    def consume_event_updated(**params)
      return unless in_replicables_for_current_secondary?

      sync_repository
    end

    def sync_repository
      Geo::ContainerRepositorySyncService.new(model_record).execute
    end
  end
end
