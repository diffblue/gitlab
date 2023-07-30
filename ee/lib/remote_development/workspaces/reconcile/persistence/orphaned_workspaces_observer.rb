# frozen_string_literal: true

module RemoteDevelopment
  module Workspaces
    module Reconcile
      module Persistence
        # noinspection RubyLocalVariableNamingConvention,RubyParameterNamingConvention - See https://handbook.gitlab.com/handbook/tools-and-tips/editors-and-ides/jetbrains-ides/code-inspection/why-are-there-noinspection-comments/
        class OrphanedWorkspacesObserver
          # @param [Hash] value
          # @return [Hash]
          def self.observe(value)
            value => {
              agent: agent, # Skip type checking so we can use fast_spec_helper
              update_type: String => update_type,
              workspace_agent_infos_by_name: Hash => workspace_agent_infos_by_name,
              workspaces_from_agent_infos: Array => workspaces_from_agent_infos,
              logger: logger, # Skip type checking to avoid coupling to Rails logger
            }

            orphaned_workspace_agent_infos = detect_orphaned_workspaces(
              workspace_agent_infos_by_name: workspace_agent_infos_by_name,
              persisted_workspace_names: workspaces_from_agent_infos.map(&:name)
            )

            if orphaned_workspace_agent_infos.present?
              logger.warn(
                message:
                  "Received orphaned workspace agent info for workspace(s) where no persisted workspace record exists",
                error_type: "orphaned_workspace",
                agent_id: agent.id,
                update_type: update_type,
                count: orphaned_workspace_agent_infos.length,
                orphaned_workspaces: orphaned_workspace_agent_infos.map do |agent_info|
                  {
                    name: agent_info.name,
                    namespace: agent_info.namespace,
                    actual_state: agent_info.actual_state
                  }
                end
              )
            end

            value
          end

          # @param [Hash] workspace_agent_infos_by_name
          # @param [Array] persisted_workspace_names
          # @return [Array]
          def self.detect_orphaned_workspaces(workspace_agent_infos_by_name:, persisted_workspace_names:)
            workspace_agent_infos_by_name.reject do |name, _|
              persisted_workspace_names.include?(name.to_s)
            end.values
          end
        end
      end
    end
  end
end
