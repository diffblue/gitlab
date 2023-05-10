# frozen_string_literal: true

module EE
  module API
    module Entities
      class GeoSite < Grape::Entity
        include ::API::Helpers::RelatedResourcesHelpers

        expose :id
        expose :name
        expose :url
        expose :internal_url
        expose :primary?, as: :primary
        expose :enabled
        expose :current do |geo_site|
          ::GeoNode.current?(geo_site)
        end
        expose :files_max_capacity
        expose :repos_max_capacity
        expose :verification_max_capacity
        expose :container_repositories_max_capacity
        expose :selective_sync_type
        expose :selective_sync_shards
        expose :namespace_ids, as: :selective_sync_namespace_ids
        expose :minimum_reverification_interval
        expose :sync_object_storage, if: ->(geo_site, _) { geo_site.secondary? }

        expose :web_edit_url do |geo_site|
          ::Gitlab::Routing.url_helpers.edit_admin_geo_node_url(geo_site)
        end

        expose :web_geo_replication_details_url, if: ->(geo_site) { geo_site.secondary? },
          proc: ->(geo_site) { geo_site.geo_replication_details_url }

        # Links should always be the last element on the list
        expose :_links do
          expose :self do |geo_site|
            expose_url api_v4_geo_sites_path(id: geo_site.id)
          end

          expose :status do |geo_site|
            expose_url api_v4_geo_sites_status_path(id: geo_site.id)
          end

          expose :repair do |geo_site|
            expose_url api_v4_geo_sites_repair_path(id: geo_site.id)
          end
        end
      end
    end
  end
end
