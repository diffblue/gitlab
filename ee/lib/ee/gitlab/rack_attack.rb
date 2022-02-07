# frozen_string_literal: true

module EE
  module Gitlab
    module RackAttack
      extend ActiveSupport::Concern

      class_methods do
        extend ::Gitlab::Utils::Override

        override :configure_throttles
        def configure_throttles(rack_attack)
          super

          throttle_or_track(rack_attack, 'throttle_incident_management_notification_web', EE::Gitlab::Throttle.incident_management_options) do |req|
            if req.alerts_notify? && EE::Gitlab::Throttle.settings.throttle_incident_management_notification_enabled
              req.path
            end
          end
        end
      end
    end
  end
end
