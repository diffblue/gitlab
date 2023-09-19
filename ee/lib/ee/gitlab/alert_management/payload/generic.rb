# frozen_string_literal: true

# Unique identification for alerts via generic alerting integration.
module EE
  module Gitlab
    module AlertManagement
      module Payload
        module Generic
          include Mappable
          extend ::Gitlab::Utils::Override

          EXCLUDED_PAYLOAD_FINGERPRINT_PARAMS = %w[start_time end_time hosts].freeze

          private

          # Currently we use full payloads, when generating a fingerprint.
          # This results in a quite strict fingerprint.
          # Over time we can relax these rules.
          # See https://gitlab.com/gitlab-org/gitlab/-/issues/214557#note_362795447
          override :plain_gitlab_fingerprint
          def plain_gitlab_fingerprint
            strong_memoize(:plain_gitlab_fingerprint) do
              next super if super.present?
              next unless generic_alert_fingerprinting_enabled?

              payload_excluding_params = payload.excluding(EXCLUDED_PAYLOAD_FINGERPRINT_PARAMS)

              next if payload_excluding_params.none? { |_, v| v.present? }

              payload_excluding_params
            end
          end

          def generic_alert_fingerprinting_enabled?
            project.feature_available?(:generic_alert_fingerprinting)
          end
        end
      end
    end
  end
end
