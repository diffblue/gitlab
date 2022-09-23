# frozen_string_literal: true

module EE
  module Repositories
    module GitHttpClientController
      extend ActiveSupport::Concern

      # This module is responsible for determining if an incoming Geo secondary
      # bound HTTP request should be redirected to the Primary.
      #
      # Why?  A secondary is not allowed to perform any write actions, so any
      # request of this type needs to be sent through to the Primary.  By
      # redirecting within code, we allow clients to git pull/push using their
      # secondary git remote without needing an additional primary remote.
      #
      # The method for redirection *must* happen as early as possible in the
      # request.  For example, putting the redirection logic in #access_check
      # will not work because the git client will not accept a 302 in response
      # to verifying credentials.
      #
      # Current secondary HTTP requests to redirect: -
      #
      # * git pull (repository is not replicated)
      #   * GET   /namespace/repo.git/info/refs?service=git-upload-pack
      #
      # * git lfs pull (repository is not replicated)
      #   * GET   /namespace/repo.git/gitlab-lfs/objects/<oid>
      #
      # * git push
      #   * GET   /namespace/repo.git/info/refs?service=git-receive-pack
      #   * POST  /namespace/repo.git/git-receive-pack
      #
      # * git lfs push (usually happens automatically as part of a `git push`)
      #   * POST  /namespace/repo.git/info/lfs/objects/batch (and we examine
      #     params[:operation] to ensure we're dealing with an upload request)
      #
      # For more detail, see the following links:
      #
      # git: https://git-scm.com/book/en/v2/Git-Internals-Transfer-Protocols
      # git-lfs: https://github.com/git-lfs/git-lfs/blob/master/docs/api
      #
      prepended do
        prepend_before_action do
          redirect_to(geo_primary_full_url) if geo_redirect?
        end
      end

      private

      class GeoRouteHelper
        attr_reader :controller_name, :action_name

        CONTROLLER_AND_ACTIONS_TO_REDIRECT = {
          'git_http' => %w{git_receive_pack},
          'lfs_locks_api' => %w{create unlock verify}
        }.freeze

        def initialize(project, controller_name, action_name, service)
          @project = project
          @controller_name = controller_name
          @action_name = action_name
          @service = service
        end

        def match?(c_name, a_name)
          controller_name == c_name && action_name == a_name
        end

        def redirect?
          !!CONTROLLER_AND_ACTIONS_TO_REDIRECT[controller_name]&.include?(action_name) ||
            git_receive_pack_request? ||
            redirect_to_avoid_enumeration? ||
            out_of_date_redirect?
        end

        def out_of_date_redirect?
          return false unless project

          git_upload_pack_request? && ::Geo::ProjectRegistry.repository_out_of_date?(project.id)
        end

        private

        attr_reader :project, :service

        # Examples:
        #
        # /repo.git/info/refs?service=git-receive-pack returns 'git-receive-pack'
        # /repo.git/info/refs?service=git-upload-pack returns 'git-upload-pack'
        # /repo.git/git-receive-pack returns 'git-receive-pack'
        # /repo.git/git-upload-pack returns 'git-upload-pack'
        #
        def service_or_action_name
          info_refs_request? ? service : action_name.dasherize
        end

        # Matches:
        #
        # GET  /repo.git/info/refs?service=git-receive-pack
        # POST /repo.git/git-receive-pack
        #
        def git_receive_pack_request?
          service_or_action_name == 'git-receive-pack'
        end

        # Matches:
        #
        # GET /repo.git/info/refs?service=git-upload-pack
        #
        def git_upload_pack_request?
          service_or_action_name == 'git-upload-pack'
        end

        # Matches:
        #
        # GET /repo.git/info/refs
        #
        def info_refs_request?
          action_name == 'info_refs'
        end

        # The purpose of the #redirect_to_avoid_enumeration? method is to avoid
        # a scenario where an authenticated user uses the HTTP responses as a
        # way of enumerating private projects.  Without this check, an attacker
        # could determine if a project exists or not by looking at the initial
        # HTTP response code for 401 (doesn't exist) vs 302. (exists).
        #
        def redirect_to_avoid_enumeration?
          project.nil?
        end
      end

      class GeoGitLFSHelper
        MINIMUM_GIT_LFS_VERSION = '2.4.2'

        def initialize(project, geo_route_helper, operation, current_version)
          @project = project
          @geo_route_helper = geo_route_helper
          @operation = operation
          @current_version = current_version
        end

        def incorrect_version_response
          {
            json: { message: incorrect_version_message },
            content_type: ::LfsRequest::CONTENT_TYPE,
            status: 403
          }
        end

        def redirect?
          return true if batch_upload?
          return true if out_of_date_redirect?

          false
        end

        def version_ok?
          return false unless current_version

          ::Gitlab::VersionInfo.parse(current_version) >= wanted_version
        end

        private

        attr_reader :project, :geo_route_helper, :operation, :current_version

        def incorrect_version_message
          translation = _("You need git-lfs version %{min_git_lfs_version} (or greater) to continue. Please visit https://git-lfs.github.com")
          translation % { min_git_lfs_version: MINIMUM_GIT_LFS_VERSION }
        end

        def batch_request?
          geo_route_helper.match?('lfs_api', 'batch')
        end

        def batch_upload?
          batch_request? && operation == 'upload'
        end

        def batch_download?
          batch_request? && operation == 'download'
        end

        def out_of_date_redirect?
          return false unless project

          batch_download? && ::Geo::ProjectRegistry.repository_out_of_date?(project.id)
        end

        def wanted_version
          ::Gitlab::VersionInfo.parse(MINIMUM_GIT_LFS_VERSION)
        end
      end

      def geo_route_helper
        @geo_route_helper ||= GeoRouteHelper.new(project, controller_name, action_name, params[:service])
      end

      def geo_git_lfs_helper
        # params[:operation] explained: https://github.com/git-lfs/git-lfs/blob/master/docs/api/batch.md#requests
        @geo_git_lfs_helper ||= GeoGitLFSHelper.new(project, geo_route_helper, params[:operation], request.headers['User-Agent'])
      end

      def geo_request_fullpath_for_primary
        relative_url_root = ::Gitlab.config.gitlab.relative_url_root.chomp('/')
        request.fullpath.sub(relative_url_root, '')
      end

      def geo_primary_full_url
        path = File.join(geo_secondary_referrer_path_prefix, geo_request_fullpath_for_primary)

        ::Gitlab::Utils.append_path(::Gitlab::Geo.primary_node_url, path)
      end

      def geo_secondary_referrer_path_prefix
        File.join(::Gitlab::Geo::GitPushHttp::PATH_PREFIX, ::Gitlab::Geo.current_node.id.to_s)
      end

      def geo_redirect?
        return false unless ::Gitlab::Geo.secondary_with_primary?
        return true if geo_route_helper.redirect?

        if geo_git_lfs_helper.redirect?
          return true if geo_git_lfs_helper.version_ok?

          # git-lfs 2.4.2 is really only required for requests that involve
          # redirection, so we only render if it's an LFS upload operation
          #
          render(geo_git_lfs_helper.incorrect_version_response)

          return false
        end

        false
      end
    end
  end
end
