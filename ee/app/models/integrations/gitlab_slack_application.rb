# frozen_string_literal: true

module Integrations
  class GitlabSlackApplication < Integration
    attribute :category, default: 'chat'

    has_one :slack_integration, foreign_key: :integration_id

    def self.supported_events
      %w()
    end

    def show_active_box?
      false
    end

    def editable?
      false
    end

    def update_active_status
      update(active: !!slack_integration)
    end

    def testable?
      false
    end

    def title
      'Slack application'
    end

    def description
      s_('Integrations|Enable GitLab.com slash commands in a Slack workspace.')
    end

    def self.to_param
      'gitlab_slack_application'
    end

    def fields
      []
    end

    def chat_responder
      Gitlab::Chat::Responder::Slack
    end
  end
end
