# frozen_string_literal: true

module RemoteDevelopment
  module Workspaces
    module Reconcile
      module Output
        class RailsInfosObserver
          # @param [Hash] value
          # @return [Hash]
          def self.observe(value)
            value => {
              agent: agent, # Skip type checking so we can use fast_spec_helper
              update_type: String => update_type,
              workspace_rails_infos: Array => workspace_rails_infos,
              logger: logger, # Skip type checking to avoid coupling to Rails logger
            }

            logger.debug(
              message: 'Returning workspace_rails_infos',
              agent_id: agent.id,
              update_type: update_type,
              count: workspace_rails_infos.length,
              workspace_rails_infos: workspace_rails_infos.map do |rails_info|
                rails_info.reject { |k, _| k == :config_to_apply }
              end
            )

            value
          end
        end
      end
    end
  end
end
