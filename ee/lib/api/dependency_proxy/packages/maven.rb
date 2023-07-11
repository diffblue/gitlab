# frozen_string_literal: true

module API
  class DependencyProxy
    module Packages
      class Maven < ::API::Base
        include ::API::Helpers::Authentication
        helpers ::API::Helpers::PackagesHelpers
        helpers ::API::Helpers::Packages::Maven
        helpers ::API::Helpers::Packages::Maven::BasicAuthHelpers

        feature_category :package_registry
        urgency :low

        content_type :md5, 'text/plain'
        content_type :sha1, 'text/plain'
        content_type :binary, 'application/octet-stream'

        helpers do
          include ::Gitlab::Utils::StrongMemoize

          def project
            authorized_user_project(action: :read_package)
          end

          def dependency_proxy_setting
            setting = project.dependency_proxy_packages_setting
            return unless setting&.enabled

            return setting if can?(current_user, :read_package, setting)
            # guest users can have :read_project but not :read_package
            return forbidden! if can?(current_user, :read_project, project)
          end
          strong_memoize_attr :dependency_proxy_setting
        end

        after_validation do
          require_packages_enabled!
          require_dependency_proxy_enabled!
        end

        authenticate_with do |accept|
          accept.token_types(:personal_access_token).sent_through(:http_private_token_header)
          accept.token_types(:deploy_token).sent_through(:http_deploy_token_header)
          accept.token_types(:job_token).sent_through(:http_job_token_header)
          accept.token_types(
            :personal_access_token_with_username,
            :deploy_token_with_username,
            :job_token_with_username
          ).sent_through(:http_basic_auth)
        end

        params do
          requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
        end
        resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
          desc 'Proxy the download of a maven package file at a project level' do
            detail 'This feature was introduced in GitLab 16.2'
            success [
              { code: 200 }
            ]
            failure [
              { code: 401, message: 'Unauthorized' },
              { code: 403, message: 'Forbidden' },
              { code: 404, message: 'Not Found' }
            ]
            tags %w[maven_packages]
            produces %w[application/octet-stream]
          end
          params do
            use :path_and_file_name
          end
          get ':id/dependency_proxy/packages/maven/*path/:file_name',
            requirements: ::API::MavenPackages::MAVEN_ENDPOINT_REQUIREMENTS do
            unless Feature.enabled?(:packages_dependency_proxy_maven, project) && dependency_proxy_setting
              unauthorized_or! { not_found! }
            end

            unauthorized_or! { forbidden! } unless project.licensed_feature_available?(:dependency_proxy_for_packages)

            # TODO: See https://gitlab.com/gitlab-org/gitlab/-/issues/410719.
            accepted!
          end
        end
      end
    end
  end
end
