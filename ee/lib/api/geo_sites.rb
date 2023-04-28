# frozen_string_literal: true

module API
  class GeoSites < ::API::Base
    include PaginationParams
    include APIGuard

    feature_category :geo_replication
    urgency :low

    before do
      authenticate_admin_or_geo_site!
    end

    helpers do
      def authenticate_admin_or_geo_site!
        if gitlab_geo_node_token?
          bad_request! unless update_geo_sites_endpoint?
          check_gitlab_geo_request_ip!
          allow_paused_nodes!
          authenticate_by_gitlab_geo_node_token!
        else
          authenticated_as_admin!
        end
      end

      def update_geo_sites_endpoint?
        request.put? && request.path.match?(%r{/geo_sites/\d+})
      end
    end

    resource :geo_sites do
      # Example request:
      #   POST /geo_sites
      desc 'Create a new Geo site' do
        summary 'Creates a new Geo site'
        success code: 200, model: EE::API::Entities::GeoSite
        failure [
          { code: 400, message: 'Validation error' },
          { code: 401, message: '401 Unauthorized' },
          { code: 403, message: '403 Forbidden' }
        ]
        tags %w[geo_sites]
      end
      params do
        optional :primary, type: Boolean, desc: 'Specifying whether this site will be primary. Defaults to false.'
        optional :enabled, type: Boolean, desc: 'Specifying whether this site will be enabled. Defaults to true.'
        requires :name, type: String,
          desc: 'The unique identifier for the Geo site. Must match `geo_node_name` if it is set in `gitlab.rb`, ' \
                'otherwise it must match `external_url`'
        requires :url, type: String, desc: 'The user-facing URL for the Geo site'
        optional :internal_url, type: String,
          desc: 'The URL defined on the primary site that secondary site should use to contact it. ' \
                'Returns `url` if not set.'
        optional :files_max_capacity, type: Integer,
          desc: 'Control the maximum concurrency of LFS/attachment backfill for this secondary site. Defaults to 10.'
        optional :repos_max_capacity, type: Integer,
          desc: 'Control the maximum concurrency of repository backfill for this secondary site. Defaults to 25.'
        optional :verification_max_capacity, type: Integer,
          desc: 'Control the maximum concurrency of repository verification for this site. Defaults to 100.'
        optional :container_repositories_max_capacity, type: Integer,
          desc: 'Control the maximum concurrency of container repository sync for this site. Defaults to 10.'
        optional :sync_object_storage, type: Boolean,
          desc: 'Flag indicating if the secondary Geo site will replicate blobs in Object Storage. Defaults to false.'
        optional :selective_sync_type, type: String,
          desc: 'Limit syncing to only specific groups, or shards. Valid values: `"namespaces"`, `"shards"`, or `null`'
        optional :selective_sync_shards, type: Array[String],
          coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce,
          desc: 'The repository storages whose projects should be synced, if `selective_sync_type` == `shards`'
        optional :selective_sync_namespace_ids, as: :namespace_ids, type: Array[Integer],
          coerce_with: Validations::Types::CommaSeparatedToIntegerArray.coerce,
          desc: 'The IDs of groups that should be synced, if `selective_sync_type` == `namespaces`'
        optional :minimum_reverification_interval, type: Integer,
          desc: 'The interval (in days) in which the repository verification is valid. Once expired, it ' \
                'will be reverified. This has no effect when set on a secondary site.'
      end
      post do
        create_params = declared_params(include_missing: false)

        new_geo_site = ::Geo::NodeCreateService.new(create_params).execute

        if new_geo_site.persisted?
          present new_geo_site, with: EE::API::Entities::GeoSite
        else
          render_validation_error!(new_geo_site)
        end
      end

      # Example request:
      #   GET /geo_sites
      desc 'Retrieves the available Geo sites' do
        summary 'Retrieve configuration about all Geo sites'
        success code: 200, model: EE::API::Entities::GeoSite
        failure [
          { code: 400, message: '400 Bad request' },
          { code: 401, message: '401 Unauthorized' },
          { code: 403, message: '403 Forbidden' }
        ]
        is_array true
        tags %w[geo_sites]
      end
      params do
        use :pagination
      end

      get do
        sites = GeoNode.all

        present paginate(sites), with: EE::API::Entities::GeoSite
      end

      # Example request:
      #   GET /geo_sites/status
      desc 'Get status for all Geo sites' do
        summary 'Get all Geo site statuses'
        success code: 200, model: EE::API::Entities::GeoSiteStatus
        failure [
          { code: 400, message: '400 Bad request' },
          { code: 401, message: '401 Unauthorized' },
          { code: 403, message: '403 Forbidden' }
        ]
        is_array true
        tags %w[geo_sites]
      end
      params do
        use :pagination
      end
      get '/status' do
        status = GeoNodeStatus.all

        present paginate(status), with: EE::API::Entities::GeoSiteStatus
      end

      # Example request:
      #   GET /geo_sites/current/failures
      desc 'Get project sync or verification failures that occurred on the current site' do
        summary 'Get project registry failures for the current Geo site'
        success code: 200, model: ::GeoProjectRegistryEntity
        failure [
          { code: 400, message: '400 Bad request' },
          { code: 401, message: '401 Unauthorized' },
          { code: 403, message: '403 Forbidden' },
          { code: 404, message: '404 Failure type unknown Not Found' }
        ]
        is_array true
        tags %w[geo_sites]
      end
      params do
        optional :type, type: String, values: %w[wiki repository], desc: 'Type of failure (repository/wiki)'
        optional :failure_type, type: String, values: %w[sync checksum_mismatch verification], default: 'sync',
          desc: 'Show verification failures'
        use :pagination
      end
      get '/current/failures' do
        not_found!('Geo site not found') unless Gitlab::Geo.current_node
        forbidden!('Failures can only be requested from a secondary site') unless Gitlab::Geo.current_node.secondary?

        type = params[:type].to_s.to_sym

        project_registries =
          case params[:failure_type]
          when 'sync'
            ::Geo::ProjectRegistry.sync_failed(type)
          when 'verification'
            ::Geo::ProjectRegistry.verification_failed(type)
          when 'checksum_mismatch'
            ::Geo::ProjectRegistry.mismatch(type)
          end

        present paginate(project_registries), with: ::GeoProjectRegistryEntity
      end

      route_param :id, type: Integer, desc: 'The ID of the site' do
        helpers do
          include ::Gitlab::Utils::StrongMemoize

          def geo_site
            GeoNode.find(params[:id])
          end
          strong_memoize_attr :geo_site

          def geo_site_status
            status = GeoNodeStatus.fast_current_node_status if GeoNode.current?(geo_site)
            status || geo_site.status
          end
          strong_memoize_attr :geo_site_status
        end

        # Example request:
        #   GET /geo_sites/:id
        desc 'Get a single GeoSite' do
          summary 'Retrieve configuration about a specific Geo site'
          success code: 200, model: EE::API::Entities::GeoSite
          failure [
            { code: 400, message: '400 Bad request' },
            { code: 401, message: '401 Unauthorized' },
            { code: 403, message: '403 Forbidden' },
            { code: 404, message: '404 GeoSite Not Found' }
          ]
          tags %w[geo_sites]
        end
        get do
          not_found!('GeoSite') unless geo_site

          present geo_site, with: EE::API::Entities::GeoSite
        end

        # Example request:
        #   GET /geo_sites/:id/status
        desc 'Get metrics for a single Geo site' do
          summary 'Get Geo metrics for a single site'
          success code: 200, model: EE::API::Entities::GeoSiteStatus
          failure [
            { code: 400, message: '400 Bad request' },
            { code: 401, message: '401 Unauthorized' },
            { code: 403, message: '403 Forbidden' },
            { code: 404, message: '404 GeoSite Not Found' }
          ]
          tags %w[geo_sites]
        end
        params do
          optional :refresh, type: Boolean,
            desc: 'Attempt to fetch the latest status from the Geo site directly, ignoring the cache'
        end
        get 'status' do
          not_found!('GeoSite') unless geo_site

          not_found!('Status for Geo site not found') unless geo_site_status

          present geo_site_status, with: EE::API::Entities::GeoSiteStatus
        end

        # Example request:
        #   POST /geo_sites/:id/repair
        desc 'Repair authentication of the Geo site' do
          summary 'Repair authentication of the Geo site'
          success code: 200, model: EE::API::Entities::GeoSiteStatus
          failure [
            { code: 400, message: '400 Bad request' },
            { code: 401, message: '401 Unauthorized' },
            { code: 403, message: '403 Forbidden' },
            { code: 404, message: '404 GeoSite Not Found' }
          ]
          tags %w[geo_sites]
        end
        post 'repair' do
          not_found!('GeoSite') unless geo_site

          if !geo_site.missing_oauth_application? || geo_site.repair
            status 200
            present geo_site_status, with: EE::API::Entities::GeoSiteStatus
          else
            render_validation_error!(geo_site)
          end
        end

        # Example request:
        #   PUT /geo_sites/:id
        desc 'Updates an existing Geo site' do
          summary 'Edit a Geo site'
          success code: 200, model: EE::API::Entities::GeoSite
          failure [
            { code: 400, message: '400 Bad request' },
            { code: 401, message: '401 Unauthorized' },
            { code: 403, message: '403 Forbidden' },
            { code: 404, message: '404 GeoSite Not Found' }
          ]
          tags %w[geo_sites]
        end
        params do
          optional :enabled, type: Boolean, desc: 'Flag indicating if the Geo site is enabled'
          optional :name, type: String,
            desc: 'The unique identifier for the Geo site. Must match `geo_node_name` if it is set in gitlab.rb, ' \
                  'otherwise it must match `external_url`'
          optional :url, type: String, desc: 'The user-facing URL of the Geo site'
          optional :internal_url, type: String,
            desc: 'The URL defined on the primary site that secondary sites should use to contact it. ' \
                  'Returns `url` if not set.'
          optional :files_max_capacity, type: Integer,
            desc: 'Control the maximum concurrency of LFS/attachment backfill for this secondary site'
          optional :repos_max_capacity, type: Integer,
            desc: 'Control the maximum concurrency of repository backfill for this secondary site'
          optional :verification_max_capacity, type: Integer,
            desc: 'Control the maximum concurrency of repository verification for this site'
          optional :container_repositories_max_capacity, type: Integer,
            desc: 'Control the maximum concurrency of container repository sync for this site'
          optional :sync_object_storage, type: Boolean,
            desc: 'Flag indicating if the secondary Geo site will replicate blobs in Object Storage'
          optional :selective_sync_type, type: String,
            desc: 'Limit syncing to only specific groups, or shards. Valid values: `"namespaces"`, `"shards"`, ' \
                  'or `null`'
          optional :selective_sync_shards, type: Array[String],
            coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce,
            desc: 'The repository storages whose projects should be synced, if `selective_sync_type` == `shards`'
          optional :selective_sync_namespace_ids, as: :namespace_ids, type: Array[Integer],
            coerce_with: Validations::Types::CommaSeparatedToIntegerArray.coerce,
            desc: 'The IDs of groups that should be synced, if `selective_sync_type` == `namespaces`'
          optional :minimum_reverification_interval, type: Integer,
            desc: 'The interval (in days) in which the repository verification is valid. Once expired, it ' \
                  'will be reverified. This has no effect when set on a secondary site.'
        end
        put do
          not_found!('GeoSite') unless geo_site

          update_params = declared_params(include_missing: false)

          updated_geo_site = ::Geo::NodeUpdateService.new(geo_site, update_params).execute

          if updated_geo_site
            present geo_site, with: EE::API::Entities::GeoSite
          else
            render_validation_error!(geo_site)
          end
        end

        # Example request:
        #   DELETE /geo_sites/:id
        desc 'Remove the Geo site' do
          summary 'Delete a Geo site'
          success code: 204, message: '204 No Content'
          failure [
            { code: 400, message: '400 Bad request' },
            { code: 401, message: '401 Unauthorized' },
            { code: 403, message: '403 Forbidden' },
            { code: 404, message: '404 GeoSite Not Found' }
          ]
          tags %w[geo_sites]
        end
        delete do
          not_found!('GeoSite') unless geo_site

          geo_site.destroy!

          no_content!
        end
      end
    end
  end
end
