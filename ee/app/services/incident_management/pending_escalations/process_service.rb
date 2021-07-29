# frozen_string_literal: true

module IncidentManagement
  module PendingEscalations
    class ProcessService < BaseService
      include Gitlab::Utils::StrongMemoize

      def initialize(escalation)
        @escalation = escalation
        @project = escalation.project
        @rule = escalation.rule
        @target = escalation.target
      end

      def execute
        return unless ::Gitlab::IncidentManagement.escalation_policies_available?(project)
        return if too_early_to_process?
        return if target_already_resolved?
        return unless rule # Remove in %14.3; Rule might be unavailable after deploy, but before post-migrations complete.
        return if target_status_exceeded_rule?

        notify_recipients
        create_system_notes
        destroy_escalation!
      end

      private

      attr_reader :escalation, :project, :target, :rule

      def target_already_resolved?
        return false unless target.resolved?

        destroy_escalation!
      end

      def target_status_exceeded_rule?
        target.status >= rule.status_before_type_cast
      end

      def too_early_to_process?
        Time.current < escalation.process_at
      end

      def notify_recipients
        NotificationService
          .new
          .async
          .notify_oncall_users_of_alert(oncall_notification_recipients, target)
      end

      def create_system_notes
        SystemNoteService.notify_via_escalation(target, project, oncall_notification_recipients, rule.policy)
      end

      def oncall_notification_recipients
        strong_memoize(:oncall_notification_recipients) do
          ::IncidentManagement::OncallUsersFinder.new(project, schedule: rule.oncall_schedule).execute.to_a
        end
      end

      def destroy_escalation!
        escalation.destroy!
      end
    end
  end
end
