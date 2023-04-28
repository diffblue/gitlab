# frozen_string_literal: true

module EE
  module API
    module Entities
      class GeoSiteStatus < Grape::Entity
        include ::API::Helpers::RelatedResourcesHelpers
        include ActionView::Helpers::NumberHelper

        expose :geo_node_id

        ::GeoNodeStatus::RESOURCE_STATUS_FIELDS.each do |field|
          expose field
        end

        ::GeoNodeStatus.percentage_methods.each do |method_name|
          expose method_name do |site|
            number_to_percentage(site[method_name], precision: 2)
          end
        end

        # Aliased from :project_count
        expose :repositories_count
        expose :wikis_count

        expose :replication_slots_count
        expose :replication_slots_used_count

        expose :healthy?, as: :healthy
        expose :health do |site|
          site.healthy? ? 'Healthy' : site.health
        end
        expose :health_status
        expose :missing_oauth_application

        expose :db_replication_lag_seconds

        expose :container_repositories_replication_enabled
        expose :design_repositories_replication_enabled
        expose :repositories_replication_enabled

        expose :repository_verification_enabled

        expose :replication_slots_max_retained_wal_bytes

        expose :repositories_checked_count
        expose :repositories_checked_failed_count

        expose :last_event_id
        expose :last_event_timestamp
        expose :cursor_last_event_id
        expose :cursor_last_event_timestamp

        expose :last_successful_status_check_timestamp

        expose :version
        expose :revision

        expose :selective_sync_type

        # Deprecated: remove in API v5. We use selective_sync_type instead now.
        expose :namespaces, using: ::API::Entities::NamespaceBasic

        expose :updated_at

        # We load GeoSiteStatus data in two ways:
        #
        # 1. Directly by asking a Geo site via an API call
        # 2. Via cached state in the database
        #
        # We don't yet cached the state of the shard information in the database, so if
        # we don't have this information omit from the serialization entirely.
        expose :storage_shards, using: StorageShardEntity, if: ->(status, _options) do
          status.storage_shards.present?
        end

        expose :storage_shards_match?, as: :storage_shards_match

        expose :_links do
          expose :self do |geo_site_status|
            expose_url api_v4_geo_sites_status_path(id: geo_site_status.geo_node_id)
          end

          expose :site do |geo_site_status|
            expose_url api_v4_geo_sites_path(id: geo_site_status.geo_node_id)
          end
        end

        private

        def namespaces
          object.geo_node.namespaces
        end

        def missing_oauth_application
          object.geo_node.missing_oauth_application?
        end
      end
    end
  end
end
