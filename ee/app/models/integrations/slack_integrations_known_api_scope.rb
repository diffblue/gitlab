# frozen_string_literal: true

module Integrations
  class SlackIntegrationsKnownApiScope < ApplicationRecord
    self.table_name = 'slack_integrations_authorized_scopes'

    belongs_to :known_slack_api_scope, class_name: 'Integrations::KnownSlackApiScope'
    belongs_to :slack_integration
  end
end
