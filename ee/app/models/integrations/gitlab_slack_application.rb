# frozen_string_literal: true

module Integrations
  class GitlabSlackApplication < BaseSlackNotification
    attribute :alert_events, default: false
    attribute :commit_events, default: false
    attribute :confidential_issues_events, default: false
    attribute :confidential_note_events, default: false
    attribute :deployment_events, default: false
    attribute :issues_events, default: false
    attribute :job_events, default: false
    attribute :merge_requests_events, default: false
    attribute :note_events, default: false
    attribute :pipeline_events, default: false
    attribute :push_events, default: false
    attribute :tag_push_events, default: false
    attribute :vulnerability_events, default: false
    attribute :wiki_page_events, default: false

    has_one :slack_integration, foreign_key: :integration_id

    def update_active_status
      update(active: !!slack_integration)
    end

    def title
      s_('Integrations|GitLab for Slack app')
    end

    def description
      if Feature.enabled?(:integration_slack_app_notifications, project)
        s_('Integrations|Enable slash commands and notifications for a Slack workspace.')
      else
        s_('Integrations|Enable GitLab.com slash commands in a Slack workspace.')
      end
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

    def upgrade_needed?
      slack_integration.present? && slack_integration.upgrade_needed?
    end

    private

    override :should_execute?
    def should_execute?(_data)
      return false unless Feature.enabled?(:integration_slack_app_notifications, project)

      super
    end

    override :notify
    def notify(message, opts)
      channels = Array(opts[:channel])
      return false if channels.empty?

      payload = {
        attachments: message.attachments,
        text: message.pretext,
        unfurl_links: false,
        unfurl_media: false
      }

      successes = channels.map do |channel|
        notify_slack_channel!(channel, payload)
      end

      successes.any?
    end

    def notify_slack_channel!(channel, payload)
      response = api_client.post(
        'chat.postMessage',
        payload.merge(channel: channel)
      )

      log_error('Slack API error when notifying', api_response: response.parsed_response) unless response['ok']

      response['ok']
    rescue *Gitlab::HTTP::HTTP_ERRORS => e
      Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e,
        {
          integration_id: id,
          slack_integration_id: slack_integration.id
        }
      )

      false
    end

    def api_client
      @slack_api ||= ::Slack::API.new(slack_integration)
    end

    override :metrics_key_prefix
    def metrics_key_prefix
      'i_integrations_gitlab_for_slack_app'
    end
  end
end
