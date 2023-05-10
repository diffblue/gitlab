# frozen_string_literal: true

module EE
  module API
    module Entities
      class GeoNode < Grape::Entity
        include ::API::Helpers::RelatedResourcesHelpers

        expose :id
        expose :name
        expose :url
        expose :internal_url
        expose :primary?, as: :primary
        expose :enabled
        expose :current do |geo_node|
          ::GeoNode.current?(geo_node)
        end
        expose :files_max_capacity
        expose :repos_max_capacity
        expose :verification_max_capacity
        expose :container_repositories_max_capacity
        expose :selective_sync_type
        expose :selective_sync_shards
        expose :namespace_ids, as: :selective_sync_namespace_ids
        expose :minimum_reverification_interval
        expose :sync_object_storage, if: ->(geo_node, _) { geo_node.secondary? }

        # Retained for backwards compatibility. Remove in API v5
        expose :clone_protocol do |_record, _options|
          'http'
        end

        expose :web_edit_url do |geo_node|
          ::Gitlab::Routing.url_helpers.edit_admin_geo_node_url(geo_node)
        end

        # @deprecated in favor of web_geo_replication_details_url
        expose :web_geo_projects_url, if: ->(geo_node, _) { geo_node.secondary? } do |geo_node|
          geo_node.geo_projects_url
        end

        expose :web_geo_replication_details_url, if: ->(geo_node, _) { geo_node.secondary? } do |geo_node|
          geo_node.geo_replication_details_url
        end

        # Links should always be the last element on the list
        expose :_links do
          expose :self do |geo_node|
            expose_url api_v4_geo_nodes_path(id: geo_node.id)
          end

          expose :status do |geo_node|
            expose_url api_v4_geo_nodes_status_path(id: geo_node.id)
          end

          expose :repair do |geo_node|
            expose_url api_v4_geo_nodes_repair_path(id: geo_node.id)
          end
        end
      end
    end
  end
end
