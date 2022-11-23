# frozen_string_literal: true

module EE
  module Clusters
    module ClustersController
      extend ActiveSupport::Concern

      prepended do
        before_action :expire_etag_cache, only: [:show]
      end

      def metrics
        return render_404 unless prometheus_adapter&.can_query?

        respond_to do |format|
          format.json do
            metrics = prometheus_adapter.query(:cluster) || {}

            if metrics.any?
              render json: metrics
            else
              head :no_content
            end
          end
        end
      end

      def environments
        respond_to do |format|
          format.json do
            ::Gitlab::PollingInterval.set_header(response, interval: 5_000)

            environments = ::Clusters::EnvironmentsFinder.new(cluster, current_user).execute

            ::Preloaders::Environments::DeploymentPreloader.new(environments)
              .execute_with_union(:last_deployment, { deployable: [] })

            render json: serialize_environments(
              environments.preload_for_cluster_environment_entity,
              request,
              response
            )
          end
        end
      end

      private

      def expire_etag_cache
        return if request.format.json? || !clusterable.environments_cluster_path(cluster)

        # this forces to reload json content
        ::Gitlab::EtagCaching::Store.new.tap do |store|
          store.touch(clusterable.environments_cluster_path(cluster))
        end
      end

      def serialize_environments(environments, request, response)
        ::Clusters::EnvironmentSerializer
          .new(cluster: cluster, current_user: current_user)
          .with_pagination(request, response)
          .represent(environments)
      end

      def prometheus_adapter
        return unless cluster&.integration_prometheus_available?

        cluster.integration_prometheus
      end
    end
  end
end
