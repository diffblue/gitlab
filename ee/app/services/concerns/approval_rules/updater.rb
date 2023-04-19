# frozen_string_literal: true

module ApprovalRules
  module Updater
    include ::Audit::Changes

    def action
      filter_eligible_users!
      filter_eligible_groups!
      filter_eligible_protected_branches!

      return save_rule_without_audit unless current_user

      if with_audit_logged { rule.update(params) }
        log_audit_event(rule)
        rule.reset

        success
      else
        error(rule.errors.messages)
      end
    end

    private

    def save_rule_without_audit
      if rule.update(params)
        rule.reset

        success
      else
        error(rule.errors.messages)
      end
    end

    def with_audit_logged(&block)
      name = rule.new_record? ? 'approval_rule_created' : 'update_approval_rules'
      audit_context = {
        name: name,
        author: current_user,
        scope: rule.project,
        target: rule
      }

      ::Gitlab::Audit::Auditor.audit(audit_context, &block)
    end

    def filter_eligible_users!
      return unless params.key?(:user_ids) || params.key?(:usernames)

      users = User.by_ids_or_usernames(params.delete(:user_ids), params.delete(:usernames))

      params[:users] = project.members_among(users)
    end

    def filter_eligible_groups!
      return unless params.key?(:group_ids)

      params[:groups] = Group.id_in(params.delete(:group_ids)).accessible_to_user(current_user)
    end

    def filter_eligible_protected_branches!
      return unless params.key?(:protected_branch_ids)

      protected_branch_ids = params.delete(:protected_branch_ids)

      return unless project.multiple_approval_rules_available? &&
        (skip_authorization || can?(current_user, :admin_project, project))

      params[:protected_branches] =
        ProtectedBranch
          .id_in(protected_branch_ids)
          .for_project(project)

      return unless allow_protected_branches_for_group?(project.group) && project.root_namespace.is_a?(Group)

      params[:protected_branches] +=
        ProtectedBranch.id_in(protected_branch_ids).for_group(project.root_namespace)
    end

    def allow_protected_branches_for_group?(group)
      ::Feature.enabled?(:group_protected_branches, group) ||
        ::Feature.enabled?(:allow_protected_branches_for_group, group)
    end

    def log_audit_event(rule)
      audit_changes(
        :approvals_required,
        as: 'number of required approvals',
        entity: rule.project,
        model: rule,
        event_type: 'update_approval_rules'
      )
    end
  end
end
