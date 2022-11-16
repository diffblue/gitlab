# frozen_string_literal: true

module EE
  module Gitlab
    module SlashCommands
      module IncidentManagement
        module IncidentCommand
          extend ::Gitlab::Utils::Override

          def slack_installation
            slack_workspace_id = params[:team_id]

            SlackIntegration.with_bot.find_by_team_id(slack_workspace_id)
          end
        end
      end
    end
  end
end
