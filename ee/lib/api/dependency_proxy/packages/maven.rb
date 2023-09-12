# frozen_string_literal: true

module API
  class DependencyProxy
    module Packages
      class Maven < ::API::Base
        include ::API::Helpers::Authentication
        helpers ::API::Helpers::PackagesHelpers
        helpers ::API::Helpers::Packages::Maven
        helpers ::API::Helpers::Packages::Maven::BasicAuthHelpers
        helpers ::API::Helpers::RelatedResourcesHelpers

        feature_category :package_registry
        urgency :low

        content_type :md5, 'text/plain'
        content_type :sha1, 'text/plain'
        content_type :binary, 'application/octet-stream'

        helpers do
          include ::Gitlab::Utils::StrongMemoize

          delegate :maven_external_registry_username, :maven_external_registry_password, :maven_external_registry_url,
            to: :dependency_proxy_setting

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

          def destroy_package_file(package_file)
            return unless package_file

            ::Packages::MarkPackageFilesForDestructionService.new(
              ::Packages::PackageFile.id_in(package_file.id)
            ).execute
          end

          def remote_package_file_url
            full_url = [maven_external_registry_url, declared_params[:path], declared_params[:file_name]].join('/')
            uri = Addressable::URI.parse(full_url)

            if maven_external_registry_username.present? && maven_external_registry_password.present?
              uri.user = maven_external_registry_username
              uri.password = maven_external_registry_password
            end

            uri.to_s
          end
          strong_memoize_attr :remote_package_file_url

          def respond_with(package_file:, format:)
            return package_file.file_md5 if format == 'md5'
            return package_file.file_sha1 if format == 'sha1'

            result = ::DependencyProxy::Packages::Maven::VerifyPackageFileEtagService.new(
              remote_url: remote_package_file_url,
              package_file: package_file
            ).execute

            if result.success? || (result.error? && result.reason != :wrong_etag)
              present_carrierwave_file_with_head_support!(package_file)
            elsif can?(current_user, :destroy_package, dependency_proxy_setting) &&
                can?(current_user, :create_package, dependency_proxy_setting)
              destroy_package_file(package_file) if package_file

              send_and_upload_remote_url(format: format)
            else
              send_remote_url(remote_package_file_url)
            end
          end

          def send_remote_url(url)
            header(*Gitlab::Workhorse.send_url(url, allow_redirects: true))
            env['api.format'] = :binary
            status :ok
            body ''
          end

          def send_dependency(headers, url, upload_config: {})
            header(*Gitlab::Workhorse.send_dependency(headers, url, upload_config: upload_config))
            env['api.format'] = :binary
            status :ok
            body ''
          end

          def send_and_upload_remote_url(format:)
            if format == 'md5' || format == 'sha1'
              # We don't store those formats. Fall back to sending the file from the remote registry.
              return send_remote_url(remote_package_file_url)
            end

            upload_config = {
              method: 'PUT',
              url: upload_url,
              headers: upload_headers
            }

            send_dependency({}, remote_package_file_url, upload_config: upload_config)
          end

          def upload_url
            url = api_v4_projects_packages_maven_path_path(
              {
                id: dependency_proxy_setting.project_id,
                path: declared_params[:path],
                file_name: declared_params[:file_name]
              },
              true
            )
            expose_url(url)
          end

          # if the endpoint was accessed by custom http headers: nothing to do.
          # if basic auth was used: transpose credentials from basic auth to custom http headers
          def upload_headers
            return {} unless has_basic_credentials?(current_request)

            header_name = case token_from_namespace_inheritable
                          when PersonalAccessToken
                            'Private-Token'
                          when DeployToken
                            'Deploy-Token'
                          when ::Ci::Build
                            ::Gitlab::Auth::CI_JOB_USER
                          end
            return {} unless header_name

            _, token = user_name_and_password(current_request)
            { header_name => token }
          end
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

            file_name, format = extract_format(params[:file_name])
            package = fetch_package(project: project, file_name: file_name)
            package_file = ::Packages::PackageFileFinder.new(package, file_name).execute if package

            if package && package_file
              respond_with(package_file: package_file, format: format)
            elsif can?(current_user, :create_package, dependency_proxy_setting)
              send_and_upload_remote_url(format: format)
            else
              send_remote_url(remote_package_file_url)
            end
          end
        end
      end
    end
  end
end
