# frozen_string_literal: true

module RemoteDevelopment
  module Workspaces
    module Reconcile
      module Persistence
        # rubocop:disable Layout/LineLength
        # noinspection RubyLocalVariableNamingConvention,RubyClassModuleNamingConvention,RubyClassMethodNamingConvention,RubyParameterNamingConvention - See https://handbook.gitlab.com/handbook/tools-and-tips/editors-and-ides/jetbrains-ides/code-inspection/why-are-there-noinspection-comments/
        # rubocop:enable Layout/LineLength
        # noinspection RubyResolve - https://handbook.gitlab.com/handbook/tools-and-tips/editors-and-ides/jetbrains-ides/tracked-jetbrains-issues/#ruby-31542
        class WorkspacesFromAgentInfosUpdater
          # @param [Hash] value
          # @return [Hash]
          def self.update(value)
            value => {
              agent: agent, # Skip type checking to avoid coupling to Rails monolith
              workspace_agent_infos_by_name: Hash => workspace_agent_infos_by_name,
            }

            workspaces_from_agent_infos = agent.workspaces.where(name: workspace_agent_infos_by_name.keys).to_a # rubocop:disable CodeReuse/ActiveRecord

            # Update persisted workspaces which match the names of the workspaces in the AgentInfo objects array
            workspaces_from_agent_infos.each do |persisted_workspace|
              workspace_agent_info = workspace_agent_infos_by_name.fetch(persisted_workspace.name.to_sym)
              # Update the persisted workspaces with the latest info from the AgentInfo objects we received
              update_persisted_workspace_with_latest_info(
                persisted_workspace: persisted_workspace,
                deployment_resource_version: workspace_agent_info.deployment_resource_version,
                actual_state: workspace_agent_info.actual_state
              )
            end

            value.merge(
              workspaces_from_agent_infos: workspaces_from_agent_infos
            )
          end

          # @param [RemoteDevelopment::Workspace] persisted_workspace
          # @param [String] deployment_resource_version
          # @param [String] actual_state
          # @return [void]
          def self.update_persisted_workspace_with_latest_info(
            persisted_workspace:,
            deployment_resource_version:,
            actual_state:
          )
            # Handle the special case of RESTART_REQUESTED. desired_state is only set to 'RESTART_REQUESTED' until the
            # actual_state is detected as 'STOPPED', then we switch the desired_state to 'RUNNING' so it will restart.
            # See: https://gitlab.com/gitlab-org/remote-development/gitlab-remote-development-docs/blob/main/doc/architecture.md?plain=0#possible-desired_state-values
            if persisted_workspace.desired_state == States::RESTART_REQUESTED && actual_state == States::STOPPED
              persisted_workspace.desired_state = States::RUNNING
            end

            # Ensure workspaces are terminated after max time-to-live. This is a temporary approach, we eventually want
            # to replace this with some mechanism to detect workspace activity and only shut down inactive workspaces.
            # Until then, this is the workaround to ensure workspaces don't live indefinitely.
            # See https://gitlab.com/gitlab-org/gitlab/-/issues/390597
            if persisted_workspace.created_at + persisted_workspace.max_hours_before_termination.hours < Time.current
              persisted_workspace.desired_state = States::TERMINATED
            end

            persisted_workspace.actual_state = actual_state

            # In some cases a deployment resource version may not be present, e.g. if the initial creation request for
            # workspace creation resulted in an Error.
            persisted_workspace.deployment_resource_version = deployment_resource_version if deployment_resource_version

            persisted_workspace.save!

            nil
          end
        end
      end
    end
  end
end
