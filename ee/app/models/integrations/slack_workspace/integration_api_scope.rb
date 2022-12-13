# frozen_string_literal: true

module Integrations
  module SlackWorkspace
    class IntegrationApiScope < ApplicationRecord
      self.table_name = 'slack_integrations_scopes'

      belongs_to :slack_api_scope, class_name: 'Integrations::SlackWorkspace::ApiScope'
      belongs_to :slack_integration
    end
  end
end
