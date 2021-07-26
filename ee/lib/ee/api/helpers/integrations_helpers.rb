# frozen_string_literal: true

module EE
  module API
    module Helpers
      module IntegrationsHelpers
        extend ActiveSupport::Concern

        class_methods do
          extend ::Gitlab::Utils::Override

          override :integrations
          def integrations
            super.merge(
              'github' => [
                {
                  required: true,
                  name: :token,
                  type: String,
                  desc: 'GitHub API token with repo:status OAuth scope'
                },
                {
                  required: true,
                  name: :repository_url,
                  type: String,
                  desc: "GitHub repository URL"
                },
                {
                  required: false,
                  name: :static_context,
                  type: ::API::Integrations::Boolean,
                  desc: 'Append instance name instead of branch to status check name'
                }
              ]
            )
          end

          override :integration_classes
          def integration_classes
            [
              ::Integrations::Github,
              *super
            ]
          end

          override :chat_notification_channels
          def chat_notification_channels
            [
              *super,
              {
                required: false,
                name: :vulnerability_channel,
                type: String,
                desc: 'The name of the channel to receive vulnerability_events notifications'
              }
            ].freeze
          end

          override :chat_notification_events
          def chat_notification_events
            [
              *super,
              {
                required: false,
                name: :vulnerability_events,
                type: ::API::Integrations::Boolean,
                desc: 'Enable notifications for vulnerability_events'
              }
            ].freeze
          end
        end
      end
    end
  end
end
