# frozen_string_literal: true

module EE
  module AlertManagement
    module Alerts
      module UpdateService
        extend ::Gitlab::Utils::Override

        override :handle_status_change
        def handle_status_change
          super

          delete_pending_escalations if alert.resolved? || alert.ignored?

          old_status = alert.status_previously_was
          if !::AlertManagement::Alert.open_status?(old_status) && alert.open?
            create_pending_escalations
          end
        end

        private

        def delete_pending_escalations
          ::IncidentManagement::PendingEscalations::Alert.delete_by_target(alert)
        end

        def create_pending_escalations
          ::IncidentManagement::PendingEscalations::AlertCreateWorker.perform_async(alert.id)
        end
      end
    end
  end
end
