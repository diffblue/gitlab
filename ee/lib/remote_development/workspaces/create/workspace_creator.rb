# frozen_string_literal: true

module RemoteDevelopment
  module Workspaces
    module Create
      class WorkspaceCreator
        include States
        include Messages

        WORKSPACE_PORT = 60001

        # @param [Hash] value
        # @return [Result]
        def self.create(value)
          value => {
            devfile_yaml: String => devfile_yaml,
            processed_devfile: Hash => processed_devfile,
            volume_mounts: Hash => volume_mounts,
            personal_access_token: PersonalAccessToken => personal_access_token,
            workspace_name: String => workspace_name,
            workspace_namespace: String => workspace_namespace,
            params: Hash => params,
          }
          volume_mounts => { data_volume: Hash => data_volume }
          data_volume => {
            path: String => workspace_root,
          }
          params => {
            project: Project => project,
          }
          project_dir = "#{workspace_root}/#{project.path}"

          workspace = RemoteDevelopment::Workspace.new(params)
          workspace.name = workspace_name
          workspace.namespace = workspace_namespace
          workspace.personal_access_token = personal_access_token
          # noinspection RubyResolve - https://handbook.gitlab.com/handbook/tools-and-tips/editors-and-ides/jetbrains-ides/tracked-jetbrains-issues/#ruby-31542
          workspace.devfile = devfile_yaml
          # noinspection RubyResolve - https://handbook.gitlab.com/handbook/tools-and-tips/editors-and-ides/jetbrains-ides/tracked-jetbrains-issues/#ruby-31542
          workspace.processed_devfile = YAML.dump(processed_devfile.deep_stringify_keys)
          # noinspection RubyResolve - https://handbook.gitlab.com/handbook/tools-and-tips/editors-and-ides/jetbrains-ides/tracked-jetbrains-issues/#ruby-31542
          workspace.actual_state = CREATION_REQUESTED
          workspace.config_version = RemoteDevelopment::Workspaces::ConfigVersion::VERSION_2
          workspace.url = URI::HTTPS.build({
            host: workspace_host(workspace: workspace),
            query: {
              folder: project_dir
            }.to_query
          }).to_s
          workspace.save

          if workspace.errors.present?
            return Result.err(
              WorkspaceModelCreateFailed.new({ errors: workspace.errors })
            )
          end

          Result.ok(
            value.merge({
              workspace: workspace
            })
          )
        end

        # @param [Workspace] workspace
        # @return [String (frozen)]
        def self.workspace_host(workspace:)
          "#{WORKSPACE_PORT}-#{workspace.name}.#{workspace.dns_zone}"
        end
      end
    end
  end
end
