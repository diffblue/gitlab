# frozen_string_literal: true

module EE
  module AlertManagement
    module AlertProcessing
      extend ::Gitlab::Utils::Override

      private

      override :complete_post_processing_tasks
      def complete_post_processing_tasks
        super

        process_escalations if escalation_policies_available?
      end

      def process_escalations
        if alert.resolved? || alert.ignored?
          delete_pending_escalations
        elsif alert.previously_new_record?
          create_pending_escalations
        end
      end

      def escalation_policies_available?
        ::Gitlab::IncidentManagement.escalation_policies_available?(project)
      end

      def delete_pending_escalations
        ::IncidentManagement::PendingEscalations::Alert.delete_by_target(alert)
      end

      def create_pending_escalations
        ::IncidentManagement::PendingEscalations::AlertCreateWorker.perform_async(alert.id)
      end
    end
  end
end
