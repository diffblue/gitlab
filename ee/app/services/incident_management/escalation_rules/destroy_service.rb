# frozen_string_literal: true

module IncidentManagement
  module EscalationRules
    # Permanently deletes escalation rules in bulk. To remove
    # a rule but allow it continue notifying for existing
    # escalations, prefer updating EscalationRule#is_removed.
    class DestroyService
      # @param escalation_rules [ActiveRecord::Relation<EscalationRule>] The rules to be deleted
      # @param user [User] User corresponding to escalation rules
      def initialize(escalation_rules:, user:)
        @escalation_rules = escalation_rules
        @user = user
      end

      def execute
        preload_associations
        send_user_deleted_emails

        # Records are already loaded, so `#ids` does not incur extra query & simplifies deletion
        IncidentManagement::EscalationRule.id_in(escalation_rules.ids).delete_all # rubocop: disable CodeReuse/ActiveRecord
      end

      private

      attr_reader :escalation_rules, :user

      def preload_associations
        @escalation_rules = escalation_rules.load_policy.load_project_with_routes
      end

      def send_user_deleted_emails
        escalation_rules
          .group_by(&:project)
          .each { |project, rules| send_user_rule_deleted_email(project, rules) }
      end

      def send_user_rule_deleted_email(project, rules)
        NotificationService.new.user_escalation_rule_deleted(project, user, rules)
      end
    end
  end
end
