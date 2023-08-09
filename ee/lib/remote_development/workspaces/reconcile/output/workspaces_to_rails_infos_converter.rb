# frozen_string_literal: true

module RemoteDevelopment
  module Workspaces
    module Reconcile
      module Output
        # noinspection RubyClassModuleNamingConvention,RubyClassMethodNamingConvention - See https://handbook.gitlab.com/handbook/tools-and-tips/editors-and-ides/jetbrains-ides/code-inspection/why-are-there-noinspection-comments/
        class WorkspacesToRailsInfosConverter
          include Messages
          include UpdateTypes

          # @param [Hash] value
          # @return [Hash]
          def self.convert(value)
            value => {
              update_type: String => update_type,
              workspaces_to_be_returned: Array => workspaces_to_be_returned,
              logger: logger
            }

            # Create an array of workspace_rails_info hashes based on the workspaces. These indicate the desired updates
            # to the workspace, which will be returned in the payload to the agent to be applied to kubernetes
            workspace_rails_infos = workspaces_to_be_returned.map do |workspace|
              workspace_rails_info = {
                name: workspace.name,
                namespace: workspace.namespace,
                desired_state: workspace.desired_state,
                actual_state: workspace.actual_state,
                deployment_resource_version: workspace.deployment_resource_version,
                # NOTE: config_to_apply should be returned as null if config_to_apply returned nil
                config_to_apply: config_to_apply(workspace: workspace, update_type: update_type, logger: logger)
              }

              workspace_rails_info
            end

            value.merge(workspace_rails_infos: workspace_rails_infos)
          end

          # @param [RemoteDevelopment::Workspace] workspace
          # @param [String (frozen)] update_type
          # @param [RemoteDevelopment::Logger] logger
          # @return [nil, String]
          def self.config_to_apply(workspace:, update_type:, logger:)
            return unless should_include_config_to_apply?(update_type: update_type, workspace: workspace)

            workspace_resources = DesiredConfigGenerator.generate_desired_config(workspace: workspace, logger: logger)

            desired_config_to_apply_array = workspace_resources.map do |resource|
              YAML.dump(resource.deep_stringify_keys)
            end

            return unless desired_config_to_apply_array.present?

            desired_config_to_apply_array.join
          end

          # @param [String (frozen)] update_type
          # @param [RemoteDevelopment::Workspace] workspace
          # @return [Boolean]
          def self.should_include_config_to_apply?(update_type:, workspace:)
            return true if update_type == FULL

            return true if workspace.desired_state_updated_more_recently_than_last_response_to_agent?

            false
          end
        end
      end
    end
  end
end
