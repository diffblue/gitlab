# frozen_string_literal: true

module ApprovalRules
  class FinalizeService
    attr_reader :merge_request

    def initialize(merge_request)
      @merge_request = merge_request
    end

    def execute
      return unless merge_request.merged?

      ApplicationRecord.transaction do
        if merge_request.approval_rules.regular.exists?
          merge_group_members_into_users
        else
          copy_project_approval_rules
        end

        merge_request.approval_rules.each(&:sync_approved_approvers)
      end
    end

    private

    def merge_group_members_into_users
      merge_request.approval_rules.each do |rule|
        rule.users |= rule.group_users
      end
    end

    # This freezes the approval state at the time of merge. By copying
    # project-level rules as merge request-level rules, the approval
    # state will be unaffected if project rules get changed or removed.
    def copy_project_approval_rules
      rules_by_name = merge_request.approval_rules.index_by(&:name)

      merge_request.target_project.approval_rules.each do |project_rule|
        users = project_rule.approvers
        groups = project_rule.groups.public_or_visible_to_user(merge_request.author)
        name = project_rule.name

        next unless name.present?

        rule = rules_by_name[name]

        # If the rule already exists, we just skip this one without
        # updating the current state. If the approval rules were changed
        # after merging a merge request, syncing the data might make it
        # appear as though this merge request hadn't been approved.
        next if rule

        merge_request.approval_rules.create!(
          project_rule.attributes.slice('approvals_required', 'name').merge(users: users, groups: groups)
        )
      end
    end
  end
end
