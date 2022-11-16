# frozen_string_literal: true

module Integrations
  class SlackInteractivityWorker # rubocop:disable Scalability/IdempotentWorker
    # This worker is used to handle requests for slack interactions.
    # As mentioned in slack docs https://api.slack.com/reference/interaction-payloads
    # we do not get a unique id to get an exclusive lease to ensure idempotency.
    # So we decided to not make this worker idempotent at all.
    # It can be invoked multiple times with same arguments by same user.
    include ApplicationWorker

    INTERACTIONS = {
      'view_closed' => SlackInteractions::IncidentManagement::IncidentModalClosedService
    }.freeze

    feature_category :integrations
    data_consistency :delayed
    urgency :low
    deduplicate :until_executed
    worker_has_external_dependencies!

    def self.interaction?(interaction)
      INTERACTIONS.key?(interaction)
    end

    def perform(args)
      args = args.with_indifferent_access

      log_extra_metadata_on_done(:slack_interaction, args[:slack_interaction])
      log_extra_metadata_on_done(:slack_user_id, args.dig(:params, :user, :id))
      log_extra_metadata_on_done(:slack_workspace_id, args.dig(:params, :team, :id))

      unless self.class.interaction?(args[:slack_interaction])
        Sidekiq.logger.error(
          message: 'Unknown slack_interaction',
          slack_interaction: args[:slack_interaction]
        )

        return
      end

      service_class = INTERACTIONS[args[:slack_interaction]]
      service_class.new(args[:params]).execute
    end
  end
end
