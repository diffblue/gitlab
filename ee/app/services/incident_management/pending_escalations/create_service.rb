# frozen_string_literal: true

module IncidentManagement
  module PendingEscalations
    class CreateService < ::BaseProjectService
      def initialize(escalatable)
        @escalatable = escalatable
        @target = escalatable.pending_escalation_target
        @process_time = Time.current

        super(project: target.project)
      end

      def execute
        return unless ::Gitlab::IncidentManagement.escalation_policies_available?(project) && !escalatable.resolved?
        return unless policy = escalatable.escalation_policy
        return if target.pending_escalations.upcoming.any?

        create_escalations(policy.active_rules)
      end

      private

      attr_reader :escalatable, :target, :process_time

      def create_escalations(rules)
        escalation_ids = rules.map do |rule|
          escalaton = create_escalation(rule)
          escalaton.id
        end

        process_escalations(escalation_ids)
      end

      def create_escalation(rule)
        target.pending_escalations.create!(
          rule: rule,
          process_at: rule.elapsed_time_seconds.seconds.after(process_time)
        )
      end

      def process_escalations(escalation_ids)
        args = escalation_ids.map { |id| [id] }

        class_for_check_worker.bulk_perform_async(args) # rubocop:disable Scalability/BulkPerformWithContext
      end

      def class_for_check_worker
        @class_for_check_worker ||= target.pending_escalations.klass.class_for_check_worker
      end
    end
  end
end
