# frozen_string_literal: true

module Integrations
  class GitlabSlackApplication < BaseSlackNotification
    attribute :category, default: 'chat'

    has_one :slack_integration, foreign_key: :integration_id

    def update_active_status
      update(active: !!slack_integration)
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

    override :show_active_box?
    def show_active_box?
      false
    end

    override :testable?
    def testable?
      false
    end

    # The form fields of this integration are visible only after the Slack App installation
    # flow has been completed, which causes the integration to become activated/enabled.
    override :editable?
    def editable?
      activated? && Feature.enabled?(:integration_slack_app_notifications, project)
    end

    override :fields
    def fields
      return [] unless editable?

      super
    end

    override :configurable_events
    def configurable_events
      return [] unless editable?

      super
    end

    override :requires_webhook?
    def requires_webhook?
      false
    end

    def chat_responder
      Gitlab::Chat::Responder::Slack
    end

    private

    # This method is currently a no-op, until further work is done to enable
    # notifications.
    #
    # See:
    #
    # - https://gitlab.com/gitlab-org/gitlab/-/issues/372410
    # - https://gitlab.com/gitlab-org/gitlab/-/issues/373321
    override :notify
    def notify(_message, _opts)
      true
    end

    override :metrics_key_prefix
    def metrics_key_prefix
      'i_integrations_gitlab_for_slack_app'
    end
  end
end
