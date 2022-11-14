# frozen_string_literal: true

module API
  class GeoNodes < ::API::Base
    include PaginationParams
    include APIGuard
    include ::Gitlab::Utils::StrongMemoize

    feature_category :geo_replication
    urgency :low

    before do
      authenticate_admin_or_geo_node!
    end

    helpers do
      def authenticate_admin_or_geo_node!
        if gitlab_geo_node_token?
          bad_request! unless update_geo_nodes_endpoint?
          check_gitlab_geo_request_ip!
          allow_paused_nodes!
          authenticate_by_gitlab_geo_node_token!
        else
          authenticated_as_admin!
        end
      end

      def update_geo_nodes_endpoint?
        request.put? && request.path.match?(%r{/geo_nodes/\d+})
      end
    end

    resource :geo_nodes do
      # Example request:
      #   POST /geo_nodes
      desc 'Create a new Geo node' do
        summary 'Creates a new Geo node'
        success code: 200, model: EE::API::Entities::GeoNode
        failure [
          { code: 400, message: 'Validation error' },
          { code: 401, message: '401 Unauthorized' },
          { code: 403, message: '403 Forbidden' }
        ]
        tags %w[geo_nodes]
      end
      params do
        optional :primary, type: Boolean, desc: 'Specifying whether this node will be primary. Defaults to false.'
        optional :enabled, type: Boolean, desc: 'Specifying whether this node will be enabled. Defaults to true.'
        requires :name, type: String, desc: 'The unique identifier for the Geo node. Must match `geo_node_name` if it is set in `gitlab.rb`, otherwise it must match `external_url`'
        requires :url, type: String, desc: 'The user-facing URL for the Geo node'
        optional :internal_url, type: String, desc: 'The URL defined on the primary node that secondary nodes should use to contact it. Returns `url` if not set.'
        optional :files_max_capacity, type: Integer, desc: 'Control the maximum concurrency of LFS/attachment backfill for this secondary node. Defaults to 10.'
        optional :repos_max_capacity, type: Integer, desc: 'Control the maximum concurrency of repository backfill for this secondary node. Defaults to 25.'
        optional :verification_max_capacity, type: Integer, desc: 'Control the maximum concurrency of repository verification for this node. Defaults to 100.'
        optional :container_repositories_max_capacity, type: Integer, desc: 'Control the maximum concurrency of container repository sync for this node. Defaults to 10.'
        optional :sync_object_storage, type: Boolean, desc: 'Flag indicating if the secondary Geo node will replicate blobs in Object Storage. Defaults to false.'
        optional :selective_sync_type, type: String, desc: 'Limit syncing to only specific groups, or shards. Valid values: `"namespaces"`, `"shards"`, or `null`'
        optional :selective_sync_shards, type: Array[String], coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce, desc: 'The repository storages whose projects should be synced, if `selective_sync_type` == `shards`'
        optional :selective_sync_namespace_ids, as: :namespace_ids, type: Array[Integer], coerce_with: Validations::Types::CommaSeparatedToIntegerArray.coerce, desc: 'The IDs of groups that should be synced, if `selective_sync_type` == `namespaces`'
        optional :minimum_reverification_interval, type: Integer, desc: 'The interval (in days) in which the repository verification is valid. Once expired, it will be reverified. This has no effect when set on a secondary node.'
      end
      post do
        create_params = declared_params(include_missing: false)

        new_geo_node = ::Geo::NodeCreateService.new(create_params).execute

        if new_geo_node.persisted?
          present new_geo_node, with: EE::API::Entities::GeoNode
        else
          render_validation_error!(new_geo_node)
        end
      end

      # Example request:
      #   GET /geo_nodes
      desc 'Retrieves the available Geo nodes' do
        summary 'Retrieve configuration about all Geo nodes'
        success code: 200, model: EE::API::Entities::GeoNode
        failure [
          { code: 400, message: '400 Bad request' },
          { code: 401, message: '401 Unauthorized' },
          { code: 403, message: '403 Forbidden' }
        ]
        is_array true
        tags %w[geo_nodes]
      end
      params do
        use :pagination
      end

      get do
        nodes = GeoNode.all

        present paginate(nodes), with: EE::API::Entities::GeoNode
      end

      # Example request:
      #   GET /geo_nodes/status
      desc 'Get status for all Geo nodes' do
        summary 'Get all Geo node statuses'
        success code: 200, model: EE::API::Entities::GeoNodeStatus
        failure [
          { code: 400, message: '400 Bad request' },
          { code: 401, message: '401 Unauthorized' },
          { code: 403, message: '403 Forbidden' }
        ]
        is_array true
        tags %w[geo_nodes]
      end
      params do
        use :pagination
      end
      get '/status' do
        status = GeoNodeStatus.all

        present paginate(status), with: EE::API::Entities::GeoNodeStatus
      end

      # Example request:
      #   GET /geo_nodes/current/failures
      desc 'Get project sync or verification failures that occurred on the current node' do
        summary 'Get project registry failures for the current Geo node'
        success code: 200, model: ::GeoProjectRegistryEntity
        failure [
          { code: 400, message: '400 Bad request' },
          { code: 401, message: '401 Unauthorized' },
          { code: 403, message: '403 Forbidden' },
          { code: 404, message: '404 Failure type unknown Not Found' }
        ]
        is_array true
        tags %w[geo_nodes]
      end
      params do
        optional :type, type: String, values: %w[wiki repository], desc: 'Type of failure (repository/wiki)'
        optional :failure_type, type: String, values: %w[sync checksum_mismatch verification], default: 'sync', desc: 'Show verification failures'
        use :pagination
      end
      get '/current/failures' do
        not_found!('Geo node not found') unless Gitlab::Geo.current_node
        forbidden!('Failures can only be requested from a secondary node') unless Gitlab::Geo.current_node.secondary?

        type = params[:type].to_s.to_sym

        project_registries =
          case params[:failure_type]
          when 'sync'
            ::Geo::ProjectRegistry.sync_failed(type)
          when 'verification'
            ::Geo::ProjectRegistry.verification_failed(type)
          when 'checksum_mismatch'
            ::Geo::ProjectRegistry.mismatch(type)
          else
            not_found!('Failure type unknown')
          end

        present paginate(project_registries), with: ::GeoProjectRegistryEntity
      end

      route_param :id, type: Integer, desc: 'The ID of the node' do
        helpers do
          def geo_node
            strong_memoize(:geo_node) { GeoNode.find(params[:id]) }
          end

          def geo_node_status
            strong_memoize(:geo_node_status) do
              status = GeoNodeStatus.fast_current_node_status if GeoNode.current?(geo_node)
              status || geo_node.status
            end
          end
        end

        # Example request:
        #   GET /geo_nodes/:id
        desc 'Get a single GeoNode' do
          summary 'Retrieve configuration about a specific Geo node'
          success code: 200, model: EE::API::Entities::GeoNode
          failure [
            { code: 400, message: '400 Bad request' },
            { code: 401, message: '401 Unauthorized' },
            { code: 403, message: '403 Forbidden' },
            { code: 404, message: '404 GeoNode Not Found' }
          ]
          tags %w[geo_nodes]
        end
        get do
          not_found!('GeoNode') unless geo_node

          present geo_node, with: EE::API::Entities::GeoNode
        end

        # Example request:
        #   GET /geo_nodes/:id/status
        desc 'Get metrics for a single Geo node' do
          summary 'Get Geo metrics for a single node'
          success code: 200, model: EE::API::Entities::GeoNodeStatus
          failure [
            { code: 400, message: '400 Bad request' },
            { code: 401, message: '401 Unauthorized' },
            { code: 403, message: '403 Forbidden' },
            { code: 404, message: '404 GeoNode Not Found' }
          ]
          tags %w[geo_nodes]
        end
        params do
          optional :refresh, type: Boolean, desc: 'Attempt to fetch the latest status from the Geo node directly, ignoring the cache'
        end
        get 'status' do
          not_found!('GeoNode') unless geo_node

          not_found!('Status for Geo node not found') unless geo_node_status

          present geo_node_status, with: EE::API::Entities::GeoNodeStatus
        end

        # Example request:
        #   POST /geo_nodes/:id/repair
        desc 'Repair authentication of the Geo node' do
          summary 'Repair authentication of the Geo node'
          success code: 200, model: EE::API::Entities::GeoNodeStatus
          failure [
            { code: 400, message: '400 Bad request' },
            { code: 401, message: '401 Unauthorized' },
            { code: 403, message: '403 Forbidden' },
            { code: 404, message: '404 GeoNode Not Found' }
          ]
          tags %w[geo_nodes]
        end
        post 'repair' do
          not_found!('GeoNode') unless geo_node

          if !geo_node.missing_oauth_application? || geo_node.repair
            status 200
            present geo_node_status, with: EE::API::Entities::GeoNodeStatus
          else
            render_validation_error!(geo_node)
          end
        end

        # Example request:
        #   PUT /geo_nodes/:id
        desc 'Updates an existing Geo node' do
          summary 'Edit a Geo node'
          success code: 200, model: EE::API::Entities::GeoNode
          failure [
            { code: 400, message: '400 Bad request' },
            { code: 401, message: '401 Unauthorized' },
            { code: 403, message: '403 Forbidden' },
            { code: 404, message: '404 GeoNode Not Found' }
          ]
          tags %w[geo_nodes]
        end
        params do
          optional :enabled, type: Boolean, desc: 'Flag indicating if the Geo node is enabled'
          optional :name, type: String, desc: 'The unique identifier for the Geo node. Must match `geo_node_name` if it is set in gitlab.rb, otherwise it must match `external_url`'
          optional :url, type: String, desc: 'The user-facing URL of the Geo node'
          optional :internal_url, type: String, desc: 'The URL defined on the primary node that secondary nodes should use to contact it. Returns `url` if not set.'
          optional :files_max_capacity, type: Integer, desc: 'Control the maximum concurrency of LFS/attachment backfill for this secondary node'
          optional :repos_max_capacity, type: Integer, desc: 'Control the maximum concurrency of repository backfill for this secondary node'
          optional :verification_max_capacity, type: Integer, desc: 'Control the maximum concurrency of repository verification for this node'
          optional :container_repositories_max_capacity, type: Integer, desc: 'Control the maximum concurrency of container repository sync for this node'
          optional :sync_object_storage, type: Boolean, desc: 'Flag indicating if the secondary Geo node will replicate blobs in Object Storage'
          optional :selective_sync_type, type: String, desc: 'Limit syncing to only specific groups, or shards. Valid values: `"namespaces"`, `"shards"`, or `null`'
          optional :selective_sync_shards, type: Array[String], coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce, desc: 'The repository storages whose projects should be synced, if `selective_sync_type` == `shards`'
          optional :selective_sync_namespace_ids, as: :namespace_ids, type: Array[Integer], coerce_with: Validations::Types::CommaSeparatedToIntegerArray.coerce, desc: 'The IDs of groups that should be synced, if `selective_sync_type` == `namespaces`'
          optional :minimum_reverification_interval, type: Integer, desc: 'The interval (in days) in which the repository verification is valid. Once expired, it will be reverified. This has no effect when set on a secondary node.'
        end
        put do
          not_found!('GeoNode') unless geo_node

          update_params = declared_params(include_missing: false)

          updated_geo_node = ::Geo::NodeUpdateService.new(geo_node, update_params).execute

          if updated_geo_node
            present geo_node, with: EE::API::Entities::GeoNode
          else
            render_validation_error!(geo_node)
          end
        end

        # Example request:
        #   DELETE /geo_nodes/:id
        desc 'Remove the Geo node' do
          summary 'Delete a Geo node'
          success code: 204, message: '204 No Content'
          failure [
            { code: 400, message: '400 Bad request' },
            { code: 401, message: '401 Unauthorized' },
            { code: 403, message: '403 Forbidden' },
            { code: 404, message: '404 GeoNode Not Found' }
          ]
          tags %w[geo_nodes]
        end
        delete do
          not_found!('GeoNode') unless geo_node

          geo_node.destroy!

          no_content!
        end
      end
    end
  end
end
