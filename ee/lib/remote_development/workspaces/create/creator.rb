# frozen_string_literal: true

module RemoteDevelopment
  module Workspaces
    module Create
      # noinspection RubyResolve - Rubymine isn't detecting ActiveRecord db field properties of workspace
      class Creator
        include States
        include Messages

        RANDOM_STRING_LENGTH = 6
        WORKSPACE_PORT = 60001

        # @param [Hash] value
        # @return [Result]
        def self.create(value)
          value => {
            devfile_yaml: String => devfile_yaml,
            processed_devfile: Hash => processed_devfile,
            volume_mounts: Hash => volume_mounts,
            current_user: User => user,
            params: Hash => params,
          }
          volume_mounts => { data_volume: Hash => data_volume }
          data_volume => {
            path: String => workspace_root,
          }
          params => {
            project: Project => project,
            agent: Clusters::Agent => agent,
          }

          processed_devfile_yaml = YAML.dump(processed_devfile.deep_stringify_keys)

          workspace = project.workspaces.build(params)

          workspace.devfile = devfile_yaml
          workspace.processed_devfile = processed_devfile_yaml
          workspace.actual_state = CREATION_REQUESTED

          random_string = SecureRandom.alphanumeric(RANDOM_STRING_LENGTH).downcase
          workspace.namespace = "gl-rd-ns-#{agent.id}-#{user.id}-#{random_string}"
          # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/409774
          #       We can come maybe come up with a better/cooler way to get a unique name, for now this works
          workspace.name = "workspace-#{agent.id}-#{user.id}-#{random_string}"

          project_dir = "#{workspace_root}/#{project.path}"
          workspace.url = URI::HTTPS.build({
            host: workspace_host(workspace: workspace),
            query: {
              folder: project_dir
            }.to_query
          }).to_s

          if workspace.save
            Result.ok(
              WorkspaceCreateSuccessful.new(
                value.merge({
                  workspace: workspace
                })
              )
            )
          else
            Result.err(WorkspaceCreateFailed.new({ errors: workspace.errors }))
          end
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
