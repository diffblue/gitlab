# frozen_string_literal: true

module RemoteDevelopment
  module Workspaces
    module Create
      # NOTE: Even though all this class currently does is define fixed values for volume mounts,
      #       we may want to add more logic to this class in the future, possibly to allow users
      #       control over the configuration of the volume mounts.
      class VolumeDefiner
        # @param [Hash] value
        # @return [Hash]
        def self.define(value)
          workspace_data_volume_name = "gl-workspace-data"

          # workspace_root is set to /projects as devfile parser uses this value when setting env vars
          # PROJECTS_ROOT and PROJECT_SOURCE that are available within the spawned containers
          # hence, workspace_root will be used across containers/initContainers as the place for user data
          #
          # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/408450
          #       explore in depth implications of PROJECTS_ROOT and PROJECT_SOURCE env vars with devfile team
          #       and update devfile processing to use them idiomatically / conform to devfile specifications
          workspace_root = "/projects"

          value.merge(
            volume_mounts: {
              data_volume: {
                name: workspace_data_volume_name,
                path: workspace_root
              }
            }
          )
        end
      end
    end
  end
end
