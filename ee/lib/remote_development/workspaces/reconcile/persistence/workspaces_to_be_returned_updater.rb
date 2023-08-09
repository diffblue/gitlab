# frozen_string_literal: true

module RemoteDevelopment
  module Workspaces
    module Reconcile
      module Persistence
        class WorkspacesToBeReturnedUpdater
          # @param [Hash] value
          # @return [Hash]
          def self.update(value)
            value => {
              agent: agent, # Skip type checking to avoid coupling to Rails monolith
              workspaces_to_be_returned: Array => workspaces_to_be_returned,
            }

            # Update the responded_to_agent_at at this point, after we have already done all the calculations
            # related to state. Do it as a single query, so that they will all have the same timestamp.

            workspaces_to_be_returned_ids = workspaces_to_be_returned.map(&:id)

            agent.workspaces.where(id: workspaces_to_be_returned_ids).touch_all(:responded_to_agent_at) # rubocop:disable CodeReuse/ActiveRecord

            value
          end
        end
      end
    end
  end
end
