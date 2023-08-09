# frozen_string_literal: true

module RemoteDevelopment
  module Workspaces
    module Reconcile
      module Persistence
        # rubocop:disable Layout/LineLength
        # noinspection RubyLocalVariableNamingConvention,RubyClassMethodNamingConvention,RubyParameterNamingConvention - See https://handbook.gitlab.com/handbook/tools-and-tips/editors-and-ides/jetbrains-ides/code-inspection/why-are-there-noinspection-comments/
        # rubocop:enable Layout/LineLength
        class WorkspacesToBeReturnedFinder
          include UpdateTypes

          # @param [Hash] value
          # @return [Hash]
          def self.find(value)
            value => {
              agent: agent, # Skip type checking to avoid coupling to Rails monolith
              update_type: String => update_type,
              workspaces_from_agent_infos: Array => workspaces_from_agent_infos,
            }

            workspaces_to_be_returned_query =
              generate_workspaces_to_be_returned_query(
                agent: agent,
                update_type: update_type,
                workspaces_from_agent_infos: workspaces_from_agent_infos
              )

            workspaces_to_be_returned = workspaces_to_be_returned_query.to_a

            value.merge(
              workspaces_to_be_returned: workspaces_to_be_returned
            )
          end

          # @param [Clusters::Agent] agent
          # @param [String] update_type
          # @param [Array] workspaces_from_agent_infos
          # @return [ActiveRecord::Relation]
          def self.generate_workspaces_to_be_returned_query(agent:, update_type:, workspaces_from_agent_infos:)
            # For a FULL update, return all workspaces for the agent which exist in the database
            return agent.workspaces.all if update_type == FULL

            # For a PARTIAL update, return:
            # 1. Workspaces with_desired_state_updated_more_recently_than_last_response_to_agent
            # 2. Workspaces which we received from the agent in the agent_infos array
            workspaces_from_agent_infos_ids = workspaces_from_agent_infos.map(&:id)
            agent
              .workspaces
              .with_desired_state_updated_more_recently_than_last_response_to_agent
              .or(agent.workspaces.id_in(workspaces_from_agent_infos_ids))
              .ordered_by_id
          end
        end
      end
    end
  end
end
