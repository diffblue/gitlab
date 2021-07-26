# frozen_string_literal: true

module Mutations
  module AppSec
    module Fuzzing
      module API
        module CiConfiguration
          class Create < BaseMutation
            include FindsProject

            graphql_name 'ApiFuzzingCiConfigurationCreate'

            argument :project_path, GraphQL::Types::ID,
              required: true,
              description: 'Full path of the project.'

            argument :api_specification_file, GraphQL::Types::String,
              required: true,
              description: 'File path or URL to the file that defines the API surface for scanning. '\
              'Must be in the format specified by the `scanMode` argument.'

            argument :auth_password, GraphQL::Types::String,
              required: false,
              description: 'CI variable containing the password for authenticating with the target API.'

            argument :auth_username, GraphQL::Types::String,
              required: false,
              description: 'CI variable containing the username for authenticating with the target API.'

            argument :scan_mode, ::Types::AppSec::Fuzzing::API::ScanModeEnum,
              required: true,
              description: 'The mode for API fuzzing scans.'

            argument :scan_profile, GraphQL::Types::String,
              required: false,
              description: 'Name of a default profile to use for scanning. Ex: Quick-10.'

            argument :target, GraphQL::Types::String,
              required: true,
              description: 'URL for the target of API fuzzing scans.'

            field :configuration_yaml, GraphQL::Types::String,
              null: true,
              description: "A YAML snippet that can be inserted into the project's "\
              '`.gitlab-ci.yml` to set up API fuzzing scans.'

            field :gitlab_ci_yaml_edit_path, GraphQL::Types::String,
              null: true,
              description: "The location at which the project's `.gitlab-ci.yml` file can be edited in the browser."

            authorize :create_vulnerability

            def resolve(args)
              project = authorized_find!(args[:project_path])

              create_service = ::AppSec::Fuzzing::API::CiConfigurationCreateService.new(
                container: project, current_user: current_user, params: args
              )

              {
                configuration_yaml: create_service.create[:yaml].to_yaml,
                errors: [],
                gitlab_ci_yaml_edit_path: Rails.application.routes.url_helpers.project_ci_pipeline_editor_path(project)
              }
            end

            private

            def raise_feature_off_error
              raise ::Gitlab::Graphql::Errors::ResourceNotAvailable,
                'The API fuzzing CI configuration feature is off'
            end
          end
        end
      end
    end
  end
end
