# frozen_string_literal: true

module Audit
  class ProtectedBranchesChangesAuditor < BaseChangesAuditor
    def initialize(current_user, model, old_merge_access_levels, old_push_access_levels)
      super(current_user, model)
      @old_merge_access_levels = old_merge_access_levels
      @old_push_access_levels = old_push_access_levels
    end

    def execute
      audit_changes(
        :allow_force_push,
        as: 'allow force push',
        entity: model.entity,
        model: model, event_type: 'protected_branch_allow_force_push_updated'
      )
      audit_changes(
        :code_owner_approval_required,
        as: 'code owner approval required',
        entity: model.entity, model: model,
        event_type: 'protected_branch_code_owner_approval_required_updated'
      )
      audit_access_levels
    end

    def audit_access_levels
      access_inputs = [
        ["allowed to push", @old_push_access_levels, model.push_access_levels],
        ["allowed to merge", @old_merge_access_levels, model.merge_access_levels]
      ]

      access_inputs.each do |change, old_access_levels, new_access_levels|
        next if old_access_levels == new_access_levels

        from = old_access_levels.map(&:humanize)
        to = new_access_levels.map(&:humanize)
        audit_context = {
          author: @current_user,
          scope: model.entity,
          target: model,
          message: "Changed #{change} from #{from} to #{to}",
          name: 'protected_branch_updated',
          additional_details: {
            change: change,
            from: from,
            to: to
          }
        }

        ::Gitlab::Audit::Auditor.audit(audit_context)
      end
    end

    def attributes_from_auditable_model(column)
      old = model.previous_changes[column].first
      new = model.previous_changes[column].last

      {
        from: old,
        to: new
      }
    end
  end
end
