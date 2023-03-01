# frozen_string_literal: true

module EE
  module Gitlab
    module GeoGitAccess
      include ::Gitlab::ConfigHelper
      include ::EE::GitlabRoutingHelper # rubocop: disable Cop/InjectEnterpriseEditionModule
      include GrapePathHelpers::NamedRouteMatcher
      extend ::Gitlab::Utils::Override

      private

      def geo_custom_action
        return unless geo_custom_action?

        payload = {
          'action' => 'geo_proxy_to_primary',
          'data' => {
            'api_endpoints' => custom_action_api_endpoints_for(cmd),
            'primary_repo' => primary_http_repo_internal_url,
            'geo_proxy_direct_to_primary' => ::Feature.enabled?(:geo_proxy_direct_to_primary),
            'request_headers' => proxy_direct_to_primary_headers
          }
        }

        ::Gitlab::GitAccessResult::CustomAction.new(payload, messages)
      end

      def geo_custom_action?
        return unless ::Gitlab::Database.read_only?
        return unless ::Gitlab::Geo.secondary_with_primary?

        receive_pack? || upload_pack_and_out_of_date?
      end

      def upload_pack_and_out_of_date?
        return false unless project

        upload_pack? && ::Geo::ProjectRegistry.repository_out_of_date?(project.id)
      end

      def proxy_direct_to_primary_headers
        proxy_direct_to_primary_base_request.headers
      end

      def proxy_direct_to_primary_base_request
        ::Gitlab::Geo::BaseRequest.new({
          scope: auth_scope,
          gl_id: actor_gl_id
        })
      end

      # @param [User, Key] actor a user or key which responds to `id`
      def actor_gl_id
        "#{actor_gl_id_prefix}-#{actor.id}"
      end

      def actor_gl_id_prefix
        if key?
          'key'
        elsif actor.is_a?(User)
          'user'
        elsif geo?
          raise ::Gitlab::GitAccess::ForbiddenError,
            "Unexpected actor :geo. Secondary sites don't receive Git requests from other Geo sites."
        elsif ci?
          raise ::Gitlab::GitAccess::ForbiddenError,
            'Unexpected actor :ci. CI requests use Git over HTTP.'
        else
          raise ::Gitlab::GitAccess::ForbiddenError,
            'Unknown type of actor'
        end
      end

      def auth_scope
        URI.parse(primary_http_repo_internal_url).path.gsub(%r{^/|\.git$}, '')
      end

      def messages
        messages = ::Gitlab::Geo.interacting_with_primary_message(primary_ssh_url_to_repo).split("\n")
        lag_message = current_replication_lag_message

        return messages unless lag_message

        messages + ['', lag_message]
      end

      def primary_http_repo_internal_url
        geo_primary_http_internal_url_to_repo(container)
      end

      def primary_ssh_url_to_repo
        geo_primary_ssh_url_to_repo(container)
      end

      def current_replication_lag_message
        return unless ::Gitlab::Geo.secondary?
        return if current_replication_lag == 0

        "Current replication lag: #{current_replication_lag} seconds"
      end

      def current_replication_lag
        @current_replication_lag ||= ::Gitlab::Geo::HealthCheck.new.db_replication_lag_seconds
      end

      def custom_action_api_endpoints_for(cmd)
        receive_pack? ? custom_action_push_api_endpoints : custom_action_pull_api_endpoints
      end

      def custom_action_pull_api_endpoints
        [
          api_v4_geo_proxy_git_ssh_info_refs_upload_pack_path,
          api_v4_geo_proxy_git_ssh_upload_pack_path
        ]
      end

      def custom_action_push_api_endpoints
        [
          api_v4_geo_proxy_git_ssh_info_refs_receive_pack_path,
          api_v4_geo_proxy_git_ssh_receive_pack_path
        ]
      end
    end
  end
end
