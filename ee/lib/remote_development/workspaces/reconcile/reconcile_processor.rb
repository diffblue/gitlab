# frozen_string_literal: true

# noinspection RubyResolve
module RemoteDevelopment
  module Workspaces
    module Reconcile
      class ReconcileProcessor
        include UpdateType

        # rubocop:disable Metrics/AbcSize
        def process(agent:, workspace_agent_infos:, update_type:)
          logger.debug(
            message: 'Beginning ReconcileProcessor',
            agent_id: agent.id,
            update_type: update_type
          )
          # parse an array of AgentInfo objects from the workspace_agent_infos array
          workspace_agent_infos_by_name = workspace_agent_infos.each_with_object({}) do |workspace_agent_info, hash|
            info = AgentInfoParser.new.parse(workspace_agent_info: workspace_agent_info)
            hash[info.name] = info

            next unless [States::UNKNOWN, States::ERROR].include? info.actual_state

            logger.warn(
              message: 'Abnormal workspace actual_state',
              error_type: 'abnormal_workspace_state',
              actual_state: info.actual_state,
              workspace_deployment_status: workspace_agent_info['latest_k8s_deployment_info']&.fetch('status', {}).to_s
            )
          end
          names_from_agent_infos = workspace_agent_infos_by_name.keys

          logger.debug(
            message: 'Parsed workspaces from workspace_agent_infos',
            agent_id: agent.id,
            update_type: update_type,
            count: names_from_agent_infos.length,
            workspace_agent_infos: workspace_agent_infos_by_name.values.map do |agent_info|
              {
                name: agent_info.name,
                namespace: agent_info.namespace,
                actual_state: agent_info.actual_state,
                deployment_resource_version: agent_info.deployment_resource_version
              }
            end
          )

          persisted_workspaces_from_agent_infos = agent.workspaces.where(name: names_from_agent_infos) # rubocop:disable CodeReuse/ActiveRecord

          check_for_orphaned_workspaces(
            workspace_agent_infos_by_name: workspace_agent_infos_by_name,
            persisted_workspace_names: persisted_workspaces_from_agent_infos.map(&:name),
            agent_id: agent.id,
            update_type: update_type
          )

          # Update persisted workspaces which match the names of the workspaces in the AgentInfo objects array
          persisted_workspaces_from_agent_infos.each do |persisted_workspace|
            workspace_agent_info = workspace_agent_infos_by_name[persisted_workspace.name]
            # Update the persisted workspaces with the latest info from the AgentInfo objects we received
            update_persisted_workspace_with_latest_info(
              persisted_workspace: persisted_workspace,
              deployment_resource_version: workspace_agent_info.deployment_resource_version,
              actual_state: workspace_agent_info.actual_state
            )
          end

          if update_type == FULL
            # For a FULL update, return all workspaces for the agent which exist in the database
            workspaces_to_return_in_rails_infos_query = agent.workspaces.all
          else
            # For a PARTIAL update, return:
            # 1. Workspaces with_desired_state_updated_more_recently_than_last_response_to_agent
            # 2. Workspaces which we received from the agent in the agent_infos array
            workspaces_from_agent_infos_ids = persisted_workspaces_from_agent_infos.map(&:id)
            workspaces_to_return_in_rails_infos_query =
              agent
                .workspaces
                .with_desired_state_updated_more_recently_than_last_response_to_agent
                .or(agent.workspaces.id_in(workspaces_from_agent_infos_ids))
          end

          workspaces_to_return_in_rails_infos = workspaces_to_return_in_rails_infos_query.to_a

          # Create an array workspace_rails_info hashes based on the workspaces. These indicate the desired updates
          # to the workspace, which will be returned in the payload to the agent to be applied to kubernetes
          workspace_rails_infos = workspaces_to_return_in_rails_infos.map do |workspace|
            workspace_rails_info = {
              name: workspace.name,
              namespace: workspace.namespace,
              desired_state: workspace.desired_state,
              actual_state: workspace.actual_state,
              deployment_resource_version: workspace.deployment_resource_version,
              # NOTE: config_to_apply will be null if there is no config to apply, i.e. if a guard clause returned false
              config_to_apply: config_to_apply(workspace: workspace, update_type: update_type)
            }

            workspace_rails_info
          end

          # Update the responded_to_agent_at at this point, after we have already done all the calculations
          # related to state. Do it outside of the loop so it will be a single query, and also so that they
          # will all have the same timestamp.
          # noinspection RailsParamDefResolve
          workspaces_to_return_in_rails_infos_query.touch_all(:responded_to_agent_at)

          payload = { workspace_rails_infos: workspace_rails_infos }

          logger.debug(
            message: 'Returning workspace_rails_infos',
            agent_id: agent.id,
            update_type: update_type,
            count: workspace_rails_infos.length,
            workspace_rails_infos: workspace_rails_infos.map do |rails_info|
              {
                name: rails_info.fetch(:name),
                namespace: rails_info.fetch(:namespace),
                desired_state: rails_info.fetch(:desired_state),
                actual_state: rails_info.fetch(:actual_state),
                deployment_resource_version: rails_info.fetch(:deployment_resource_version)
              }
            end
          )

          [payload, nil]
        end
        # rubocop:enable Metrics/AbcSize

        private

        def config_to_apply(workspace:, update_type:)
          # NOTE: If update_type==FULL, we always return the config.
          return if update_type == PARTIAL &&
            !workspace.desired_state_updated_more_recently_than_last_response_to_agent?

          workspace_resources = DesiredConfigGenerator.new.generate_desired_config(workspace: workspace)

          desired_config_to_apply_array = workspace_resources.map do |resource|
            YAML.dump(resource)
          end

          return unless desired_config_to_apply_array.present?

          desired_config_to_apply_array.join
        end

        def check_for_orphaned_workspaces(
          workspace_agent_infos_by_name:,
          persisted_workspace_names:,
          agent_id:,
          update_type:
        )
          orphaned_workspace_agent_infos = workspace_agent_infos_by_name.reject do |name, _|
            persisted_workspace_names.include?(name)
          end.values

          return unless orphaned_workspace_agent_infos.present?

          logger.warn(
            message:
              'Received orphaned workspace agent info for workspace(s) where no persisted workspace record exists',
            error_type: 'orphaned_workspace',
            agent_id: agent_id,
            update_type: update_type,
            count: orphaned_workspace_agent_infos.length,
            orphaned_workspace_names: orphaned_workspace_agent_infos.map(&:name),
            orphaned_workspace_namespaces: orphaned_workspace_agent_infos.map(&:namespace)
          )
        end

        def update_persisted_workspace_with_latest_info(
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

          # Ensure workspaces are terminated after a max time-to-live. This is a temporary approach, we eventually want
          # to replace this with some mechanism to detect workspace activity and only shut down inactive workspaces.
          # Until then, this is the workaround to ensure workspaces don't live indefinitely.
          # See https://gitlab.com/gitlab-org/gitlab/-/issues/390597
          if persisted_workspace.created_at + persisted_workspace.max_hours_before_termination.hours < Time.current
            persisted_workspace.desired_state = States::TERMINATED
          end

          persisted_workspace.actual_state = actual_state

          # In some cases a deployment resource version may not be present, e.g. if the initial creation request for the
          # workspace creation resulted in an Error.
          persisted_workspace.deployment_resource_version = deployment_resource_version if deployment_resource_version

          persisted_workspace.save!
        end

        # TODO: https://gitlab.com/groups/gitlab-org/-/epics/10461
        #       Dry up memoized logger factory to a shared concern
        def logger
          @logger ||= RemoteDevelopment::Logger.build
        end
      end
    end
  end
end
