# frozen_string_literal: true

module Audit
  class ProtectedEnvironmentAuthorizationRuleChangesAuditor
    AUTHORIZABLE_ATTRIBUTES = [:access_level, :user_id, :group_id].freeze

    def initialize(author:, scope:, protected_environment:, deleted_deploy_access_levels:, deleted_approval_rules:)
      @author = author
      @scope = scope
      @protected_environment = protected_environment
      @deleted_deploy_access_levels = deleted_deploy_access_levels
      @deleted_approval_rules = deleted_approval_rules
    end

    def audit
      audit_changed_deploy_access_levels
      audit_changed_approval_rules
    end

    private

    attr_reader :author, :scope, :protected_environment, :deleted_deploy_access_levels, :deleted_approval_rules

    def audit_changed_deploy_access_levels
      audit_deleted_deploy_access_levels
      audit_created_and_updated_deploy_access_levels
    end

    def audit_deleted_deploy_access_levels
      deleted_deploy_access_levels.each do |deploy_access_level|
        audit_event(
          event_name: 'protected_environment_deploy_access_level_deleted',
          message: "Deleted deploy access level #{deploy_access_level.humanize}."
        )
      end
    end

    def audit_created_and_updated_deploy_access_levels
      protected_environment.deploy_access_levels.each do |deploy_access_level|
        if deploy_access_level.previously_new_record?
          audit_event(
            event_name: 'protected_environment_deploy_access_level_added',
            message: "Added deploy access level #{deploy_access_level.humanize}."
          )
        elsif deploy_access_level_has_changes?(deploy_access_level)
          audit_event(
            event_name: 'protected_environment_deploy_access_level_updated',
            message: updated_deploy_access_level_message(deploy_access_level)
          )
        end
      end
    end

    def audit_changed_approval_rules
      audit_deleted_approval_rules
      audit_created_and_updated_approval_rules
    end

    def audit_deleted_approval_rules
      deleted_approval_rules.each do |approval_rule|
        audit_event(
          event_name: 'protected_environment_approval_rule_deleted',
          message: "Deleted approval rule for #{approval_rule.humanize}."
        )
      end
    end

    def audit_created_and_updated_approval_rules
      protected_environment.approval_rules.each do |approval_rule|
        if approval_rule.previously_new_record?
          audit_event(
            event_name: 'protected_environment_approval_rule_added',
            message: "Added approval rule for #{approval_rule.humanize} " \
                     "with required approval count #{approval_rule.required_approvals}."
          )
        elsif approval_rule_has_changes?(approval_rule)
          audit_event(
            event_name: 'protected_environment_approval_rule_updated',
            message: updated_approval_rule_message(approval_rule)
          )
        end
      end
    end

    def deploy_access_level_has_changes?(deploy_access_level)
      deploy_access_level.previous_changes.keys.any? { |key| AUTHORIZABLE_ATTRIBUTES.include?(key.to_sym) }
    end

    def updated_deploy_access_level_message(deploy_access_level)
      changed_access_levels = changed_access_level_details(deploy_access_level)
      "Changed deploy access level from #{changed_access_levels[:old_access_level]} " \
        "to #{changed_access_levels[:new_access_level]}."
    end

    def approval_rule_has_changes?(approval_rule)
      auditable_attributes = AUTHORIZABLE_ATTRIBUTES + [:required_approvals]
      approval_rule.previous_changes.keys.any? { |key| auditable_attributes.include?(key.to_sym) }
    end

    def updated_approval_rule_message(approval_rule)
      changed_access_levels = changed_access_level_details(approval_rule)
      changed_approval_counts = approval_rule.previous_changes[:required_approvals]

      if changed_access_levels.present?
        update_approval_rule_access_level_message(approval_rule, changed_access_levels, changed_approval_counts)
      else
        update_approval_rule_approval_count_message(approval_rule, changed_approval_counts)
      end
    end

    def update_approval_rule_access_level_message(approval_rule, changed_access_levels, changed_approval_counts)
      old_access_level_approval_count = changed_approval_counts&.first || approval_rule.required_approvals
      new_access_level_approval_count = approval_rule.required_approvals

      "Updated approval rule for #{changed_access_levels[:old_access_level]} " \
        "with required approval count #{old_access_level_approval_count} " \
        "to #{changed_access_levels[:new_access_level]} " \
        "with required approval count #{new_access_level_approval_count}."
    end

    def update_approval_rule_approval_count_message(approval_rule, changed_approval_counts)
      "Updated approval rule for #{approval_rule.humanize} " \
        "with required approval count " \
        "from #{changed_approval_counts.first} " \
        "to #{changed_approval_counts.last}."
    end

    def changed_access_level_details(authorizable_object)
      # The AUTHORIZABLE_ATTRIBUTES (:access_level, :user_id, :group_id) are mutually exclusive
      # This means that an authorizable_object (deploy_access_level or approval_rule)
      # can only have one of :access_level, :user_id, or :group_id present
      # A "change" can mean either of the following:
      #   - the value of the same attribute is changed, e.g.: user_id=1 to user_id=2
      #   - the value of one attribute becomes nil, and the value of another attribute is set,
      #     e.g.: { user_id: 1, access_level: nil } to { user_id: nil, access_level: 40 }
      changes = authorizable_object.previous_changes.slice(*AUTHORIZABLE_ATTRIBUTES)
      return unless changes.present?

      # changes are formatted as such: { attr_name: [old_value, new_value] }
      # the old access level is determined by which attribute has the old_value present
      # the new access level is determined by which attribute has the new_value present
      old_access_level = changes.detect { |_, changed_values| changed_values.first.present? }
      new_access_level = changes.detect { |_, changed_values| changed_values.last.present? }

      {
        old_access_level: humanize(type: old_access_level[0], value: old_access_level[1].first),
        new_access_level: humanize(type: new_access_level[0], value: new_access_level[1].last)
      }
    end

    def humanize(type:, value:)
      case type.to_sym
      when :access_level
        ::ProtectedEnvironments::DeployAccessLevel::HUMAN_ACCESS_LEVELS[value]
      when :user_id
        "user with ID #{value}"
      when :group_id
        "group with ID #{value}"
      end
    end

    def audit_event(event_name:, message:)
      ::Gitlab::Audit::Auditor.audit(
        name: event_name,
        author: author,
        scope: scope,
        target: protected_environment,
        message: message
      )
    end
  end
end
