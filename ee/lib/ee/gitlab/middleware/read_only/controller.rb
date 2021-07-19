# frozen_string_literal: true

module EE
  module Gitlab
    module Middleware
      module ReadOnly
        module Controller
          extend ::Gitlab::Utils::Override

          ALLOWLISTED_GEO_ROUTES = {
            'admin/geo/nodes' => %w{update}
          }.freeze

          ALLOWLISTED_GEO_ROUTES_TRACKING_DB = {
            'admin/geo/projects' => %w{destroy resync reverify force_redownload resync_all reverify_all},
            'admin/geo/uploads' => %w{destroy}
          }.freeze

          ALLOWLISTED_GIT_READ_WRITE_ROUTES = {
            'repositories/git_http' => %w{git_upload_pack git_receive_pack}
          }.freeze

          ALLOWLISTED_GIT_LFS_LOCKS_ROUTES = {
            'repositories/lfs_locks_api' => %w{verify create unlock}
          }.freeze

          ALLOWLISTED_SIGN_IN_ROUTES = {
            'sessions' => %w{create},
            'oauth/tokens' => %w{create}
          }.freeze

          private

          # In addition to routes allowed in FOSS, allow geo node update route
          # and geo api route, on both Geo primary and secondary.
          # If this is on a Geo secondary, also allow git write routes.
          # If in maintenance mode, don't allow git write routes on Geo
          # secondary either
          override :allowlisted_routes
          def allowlisted_routes
            allowed = super || geo_node_update_route? || geo_api_route? || admin_settings_update?

            return true if allowed
            return sign_in_route? if ::Gitlab.maintenance_mode?
            return false unless ::Gitlab::Geo.secondary?

            git_write_routes
          end

          def git_write_routes
            geo_proxy_git_ssh_route? || geo_proxy_git_http_route? || lfs_locks_route?
          end

          def admin_settings_update?
            return false if ::Gitlab::Geo.secondary?

            request.path.start_with?('/api/v4/application/settings',
                                     '/admin/application_settings/general')
          end

          def geo_node_update_route?
            # Calling route_hash may be expensive. Only do it if we think there's a possible match
            return false unless request.path.start_with?('/admin/geo/')

            controller = route_hash[:controller]
            action = route_hash[:action]

            if ALLOWLISTED_GEO_ROUTES[controller]&.include?(action)
              ::Gitlab::Database.main.db_read_write?
            else
              ALLOWLISTED_GEO_ROUTES_TRACKING_DB[controller]&.include?(action)
            end
          end

          def geo_proxy_git_ssh_route?
            ::Gitlab::Middleware::ReadOnly::API_VERSIONS.any? do |version|
              request.path.start_with?("/api/v#{version}/geo/proxy_git_ssh")
            end
          end

          def geo_proxy_git_http_route?
            return unless request_path.end_with?('.git/git-receive-pack')

            ALLOWLISTED_GIT_READ_WRITE_ROUTES[route_hash[:controller]]&.include?(route_hash[:action])
          end

          def geo_api_route?
            ::Gitlab::Middleware::ReadOnly::API_VERSIONS.any? do |version|
              request.path.include?("/api/v#{version}/geo_replication")
            end
          end

          def sign_in_route?
            return unless request.post? && request.path.start_with?('/users/sign_in', '/oauth/token')

            ALLOWLISTED_SIGN_IN_ROUTES[route_hash[:controller]]&.include?(route_hash[:action])
          end

          def lfs_locks_route?
            # Calling route_hash may be expensive. Only do it if we think there's a possible match
            unless request_path.end_with?('/info/lfs/locks', '/info/lfs/locks/verify') ||
                %r{/info/lfs/locks/\d+/unlock\z}.match?(request_path)
              return false
            end

            ALLOWLISTED_GIT_LFS_LOCKS_ROUTES[route_hash[:controller]]&.include?(route_hash[:action])
          end

          override :read_only?
          def read_only?
            ::Gitlab.maintenance_mode? || super
          end
        end
      end
    end
  end
end
