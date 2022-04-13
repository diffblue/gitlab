# frozen_string_literal: true

module EE
  module AlertManagement
    module Alert
      extend ActiveSupport::Concern

      prepended do
        include AfterCommitQueue

        has_many :pending_escalations, class_name: 'IncidentManagement::PendingEscalations::Alert', foreign_key: :alert_id, inverse_of: :alert

        after_create do |alert|
          run_after_commit { alert.trigger_auto_rollback }
        end
      end

      def trigger_auto_rollback
        return unless triggered? && critical? && environment&.auto_rollback_enabled?

        ::Deployments::AutoRollbackWorker.perform_async(environment.id)
      end
    end
  end
end
