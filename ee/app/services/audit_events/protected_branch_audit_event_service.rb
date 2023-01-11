# frozen_string_literal: true

module AuditEvents
  class ProtectedBranchAuditEventService
    attr_accessor :protected_branch

    def initialize(author, protected_branch, action)
      @action = action
      @protected_branch = protected_branch
      @author = author
    end

    def execute
      audit_context = {
        author: @author,
        scope: @protected_branch.entity,
        target: @protected_branch,
        message: message,
        name: event_type,
        additional_details: {
          push_access_levels: @protected_branch.push_access_levels.map(&:humanize),
          merge_access_levels: @protected_branch.merge_access_levels.map(&:humanize),
          allow_force_push: @protected_branch.allow_force_push,
          code_owner_approval_required: @protected_branch.code_owner_approval_required
        }
      }

      ::Gitlab::Audit::Auditor.audit(audit_context)
    end

    def event_type
      case @action
      when :add
        "protected_branch_created"
      when :remove
        "protected_branch_removed"
      end
    end

    def message
      case @action
      when :add
        "Added protected branch with ["\
        "allowed to push: #{@protected_branch.push_access_levels.map(&:humanize)}, "\
        "allowed to merge: #{@protected_branch.merge_access_levels.map(&:humanize)}, "\
        "allow force push: #{@protected_branch.allow_force_push}, "\
        "code owner approval required: #{@protected_branch.code_owner_approval_required}]"
      when :remove
        "Unprotected branch"
      else
        "no message defined for #{@action}"
      end
    end
  end
end
