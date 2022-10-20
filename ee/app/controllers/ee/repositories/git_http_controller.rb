# frozen_string_literal: true

module EE
  module Repositories
    module GitHttpController
      extend ::Gitlab::Utils::Override
      include ::Gitlab::Utils::StrongMemoize

      override :render_ok
      def render_ok
        set_workhorse_internal_api_content_type

        render json: ::Gitlab::Workhorse.git_http_ok(repository, repo_type, user, action_name, show_all_refs: geo_request?)
      end

      override :git_receive_pack
      def git_receive_pack
        # Authentication/authorization already happened in `before_action`s

        if ::Gitlab::Geo.primary?
          # This ID is used by the /internal/post_receive API call
          gl_id = ::Gitlab::GlId.gl_id(user)
          gl_repository = repo_type.identifier_for_container(container)
          node_id = params["geo_node_id"]
          ::Gitlab::Geo::GitPushHttp.new(gl_id, gl_repository).cache_referrer_node(node_id)
        end

        super
      end

      private

      override :user
      def user
        super || geo_push_user&.user
      end

      def geo_push_user
        return unless geo_gl_id

        @geo_push_user ||= ::Geo::PushUser.new(geo_gl_id) # rubocop:disable Gitlab/ModuleWithInstanceVariables
      end

      def geo_gl_id
        decoded_authorization&.dig(:gl_id)
      end

      def geo_push_proxy_request?
        geo_gl_id
      end

      def geo_request?
        ::Gitlab::Geo::JwtRequestDecoder.geo_auth_attempt?(request.headers['Authorization'])
      end

      def geo?
        authentication_result.geo?
      end

      override :access_actor
      def access_actor
        return super unless geo?
        return :geo unless geo_push_proxy_request?
        return geo_push_user.user if geo_push_user&.user

        raise ::Gitlab::GitAccess::ForbiddenError, 'Geo push user is invalid.'
      end

      override :authenticate_user
      def authenticate_user
        return super unless geo_request?
        return render_bad_geo_response('Request from this IP is not allowed') unless ip_allowed?
        return render_bad_geo_jwt('Bad token') unless decoded_authorization
        return render_bad_geo_jwt('Unauthorized scope') unless jwt_scope_valid?

        # grant access
        @authentication_result = ::Gitlab::Auth::Result.new(nil, project, :geo, [:download_code, :push_code]) # rubocop:disable Gitlab/ModuleWithInstanceVariables
      rescue ::Gitlab::Geo::InvalidDecryptionKeyError
        render_bad_geo_jwt("Invalid decryption key")
      rescue ::Gitlab::Geo::InvalidSignatureTimeError
        render_bad_geo_jwt("Invalid signature time ")
      end

      override :update_fetch_statistics
      def update_fetch_statistics
        send_git_audit_streaming_event
        super
      end

      def jwt_scope_valid?
        decoded_authorization[:scope] == repository_path.delete_suffix('.git')
      end

      def decoded_authorization
        strong_memoize(:decoded_authorization) do
          ::Gitlab::Geo::JwtRequestDecoder.new(request.headers['Authorization']).decode
        end
      end

      def render_bad_geo_jwt(message)
        render_bad_geo_response("Geo JWT authentication failed: #{message}")
      end

      def render_bad_geo_response(message)
        render plain: message, status: :unauthorized
      end

      def ip_allowed?
        ::Gitlab::Geo.allowed_ip?(request.ip)
      end

      def send_git_audit_streaming_event
        return if user.blank? || project.blank?

        audit_context = {
          name: 'repository_git_operation',
          stream_only: true,
          author: user,
          scope: project,
          target: project,
          message: { protocol: 'http', action: 'git-upload-pack' }
        }

        ::Gitlab::Audit::Auditor.audit(audit_context)
      end
    end
  end
end
