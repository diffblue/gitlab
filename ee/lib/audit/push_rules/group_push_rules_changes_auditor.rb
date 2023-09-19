# frozen_string_literal: true

module Audit
  module PushRules
    class GroupPushRulesChangesAuditor < BasePushRulesChangesAuditor
      EVENT_TYPE_PER_ATTR = {
        max_file_size: 'group_push_rules_max_file_size_updated',
        file_name_regex: 'group_push_rules_file_name_regex_updated',
        author_email_regex: 'group_push_rules_author_email_regex_updated',
        commit_message_negative_regex: 'group_push_rules_commit_message_negative_regex_updated',
        commit_message_regex: 'group_push_rules_commit_message_regex_updated',
        branch_name_regex: 'group_push_rules_branch_name_regex_updated',
        commit_committer_check: 'group_push_rules_commit_committer_check_updated',
        reject_unsigned_commits: 'group_push_rules_reject_unsigned_commits_updated',
        reject_non_dco_commits: 'group_push_rules_reject_non_dco_commits_updated',
        deny_delete_tag: 'group_push_rules_reject_deny_delete_tag_updated',
        member_check: 'group_push_rules_reject_member_check_updated',
        prevent_secrets: 'group_push_rules_prevent_secrets_updated'
      }.freeze

      def execute
        return if model.blank? || model.group.nil?

        ::PushRule::AUDIT_LOG_ALLOWLIST.each do |attr, desc|
          event_name = EVENT_TYPE_PER_ATTR[attr] || 'audit_operation'

          audit_changes(
            attr,
            as: desc,
            entity: model.group,
            model: model,
            event_type: event_name
          )
        end
      end

      private

      def target_details
        model.group.full_path
      end
    end
  end
end
