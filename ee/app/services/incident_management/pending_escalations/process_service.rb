# frozen_string_literal: true

module IncidentManagement
  module PendingEscalations
    class ProcessService < BaseService
      include Gitlab::Utils::StrongMemoize

      def initialize(escalation)
        @escalation = escalation
        @project = escalation.project
        @rule = escalation.rule
        @escalatable = escalation.escalatable
        @target = escalation.target
      end

      def execute
        return unless ::Gitlab::IncidentManagement.escalation_policies_available?(project)
        return if too_early_to_process?
        return if escalatable_already_resolved?
        return if escalatable_status_exceeded_rule?

        notify_recipients
        create_system_notes
        destroy_escalation!
      end

      private

      attr_reader :escalation, :project, :target, :rule, :escalatable

      def escalatable_already_resolved?
        return false unless escalatable.resolved?

        destroy_escalation!
      end

      def escalatable_status_exceeded_rule?
        escalatable.status >= rule.status_before_type_cast
      end

      def too_early_to_process?
        Time.current < escalation.process_at
      end

      def notify_recipients
        NotificationService
          .new
          .async
          .send("notify_oncall_users_of_#{escalation.type}", oncall_notification_recipients, target) # rubocop: disable GitlabSecurity/PublicSend
      end

      def create_system_notes
        SystemNoteService.notify_via_escalation(target, project, oncall_notification_recipients, rule.policy, escalation.type)
      end

      def oncall_notification_recipients
        strong_memoize(:oncall_notification_recipients) do
          rule.user_id ? [rule.user] : schedule_recipients
        end
      end

      def schedule_recipients
        ::IncidentManagement::OncallUsersFinder.new(project, schedule: rule.oncall_schedule).execute.to_a
      end

      def destroy_escalation!
        escalation.destroy!
      end
    end
  end
end
