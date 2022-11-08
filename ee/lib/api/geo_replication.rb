# frozen_string_literal: true

module API
  class GeoReplication < ::API::Base
    include PaginationParams
    include APIGuard
    include ::Gitlab::Utils::StrongMemoize

    feature_category :geo_replication
    urgency :low

    before do
      authenticated_as_admin!
      not_found!('Geo node not found') unless Gitlab::Geo.current_node
      forbidden!('Designs can only be requested from a secondary node') unless Gitlab::Geo.current_node.secondary?
    end

    resource :geo_replication do
      resource :designs do
        # Get designs for the current Geo node
        #
        # Example request:
        #   GET /geo_replication/designs
        desc 'Get designs for the current Geo node' do
          success ::GeoDesignRegistryEntity
        end
        params do
          optional :search,
            type: String,
            desc: 'Query term that will search over :path, :name and :description',
            documentation: { example: 'name LIKE foo%' }
          optional :sync_status,
            type: String,
            values: %w[failed synced pending],
            desc: 'The state of sync',
            documentation: { example: 'failed' }
          use :pagination
        end
        get do
          design_registries = ::Geo::DesignRegistry.search(params)

          present paginate(design_registries), with: ::GeoDesignRegistryEntity
        end

        # Resync design for the current Geo node
        #
        # Example request:
        #   PUT /geo_replication/designs/:id/resync
        desc 'Resync design for the current Geo node' do
          success ::GeoDesignRegistryEntity
        end
        params do
          optional :id, type: Integer, desc: 'ID of project', documentation: { example: 42 }
        end
        put ':id/resync' do
          ::Geo::DesignRegistry.find_by!(project_id: params[:id]).repository_updated! # rubocop: disable CodeReuse/ActiveRecord

          :ok
        end

        # Resync all the designs for the current Geo node
        #
        # Example request:
        #   POST /geo_replication/designs/resync
        desc 'Resync all the design for the current Geo node' do
          success ::GeoDesignRegistryEntity
        end
        post 'resync' do
          ::Geo::DesignRegistry.update_all(state: :pending)

          :ok
        end
      end
    end
  end
end
