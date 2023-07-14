# frozen_string_literal: true

module RemoteDevelopment
  module Workspaces
    module Create
      class DevfileFetcher
        include Messages

        # NOTE: This method should be called `load` to follow the convention of other singleton methods,
        #       but that naming causes errors due to conflicts with `Kernel#load`.
        #
        # @param [Hash] value
        # @return [Result]
        def self.fetch(value)
          value => { params: Hash => params }
          params => {
            agent: Clusters::Agent => agent,
            project: Project => project,
            devfile_ref: String => devfile_ref,
            devfile_path: String => devfile_path
          }

          unless agent.remote_development_agent_config
            return Result.err(WorkspaceCreateParamsValidationFailed.new(
              details: "No RemoteDevelopmentAgentConfig found for agent '#{agent.name}'"
            ))
          end

          repository = project.repository
          devfile_yaml = repository.blob_at_branch(devfile_ref, devfile_path)&.data

          unless devfile_yaml
            return Result.err(WorkspaceCreateDevfileLoadFailed.new(details: "Devfile could not be loaded from project"))
          end

          begin
            devfile = YAML.safe_load(devfile_yaml)
          rescue RuntimeError => e
            return Result.err(WorkspaceCreateDevfileYamlParseFailed.new(
              details: "Devfile YAML could not be parsed: #{e.message}"
            ))
          end

          Result.ok(value.merge({
            # NOTE: The devfile_yaml is not currently used by any subsequent step in the chain, but we include it in
            #       case it may provide useful context when debugging, or may be included as context with some error
            #       logging or observability in the future.
            devfile_yaml: devfile_yaml,
            devfile: devfile
          }))
        end
      end
    end
  end
end
