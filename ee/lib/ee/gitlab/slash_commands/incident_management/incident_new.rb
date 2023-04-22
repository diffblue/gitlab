# frozen_string_literal: true

module EE
  module Gitlab
    module SlashCommands
      module IncidentManagement
        module IncidentNew
          def execute(_match)
            response = ::Integrations::SlackInteractions::IncidentManagement::IncidentModalOpenedService
            .new(slack_installation, current_user, params)
            .execute

            presenter.present(response.message)
          end
        end
      end
    end
  end
end
