# frozen_string_literal: true

module AuditEvents
  class ProtectedBranchAuditEventService < ::AuditEventService
    attr_accessor :protected_branch

    def initialize(author, protected_branch, action)
      @action = action
      @protected_branch = protected_branch

      super(author, protected_branch.project,
            { author_name: author.name,
              custom_message: message,
              target_id: protected_branch.id,
              target_type: protected_branch.class.name,
              target_details: protected_branch.name,
              push_access_levels: protected_branch.push_access_levels.map(&:humanize),
              merge_access_levels: protected_branch.merge_access_levels.map(&:humanize),
              allow_force_push: protected_branch.allow_force_push,
              code_owner_approval_required: protected_branch.code_owner_approval_required }
      )
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
