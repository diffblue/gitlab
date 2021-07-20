# frozen_string_literal: true
module ComplianceManagement
  module MergeRequestApprovalSettings
    class Resolver
      def initialize(group)
        @group = group
      end

      def execute
        {
          allow_author_approval: allow_author_approval,
          allow_committer_approval: allow_committer_approval,
          allow_overrides_to_approver_list_per_merge_request: allow_overrides_to_approver_list_per_merge_request,
          retain_approvals_on_push: retain_approvals_on_push,
          require_password_to_approve: require_password_to_approve
        }
      end

      def allow_author_approval
        instance_value = instance_settings.current_application_settings.prevent_merge_requests_author_approval
        group_value = group_settings&.allow_author_approval

        setting(:allow_author_approval, instance_value, group_value, default: true)
      end

      def allow_committer_approval
        instance_value = instance_settings.prevent_merge_requests_committers_approval
        group_value = group_settings&.allow_committer_approval

        setting(:allow_committer_approval, instance_value, group_value, default: true)
      end

      def allow_overrides_to_approver_list_per_merge_request
        instance_value = instance_settings.disable_overriding_approvers_per_merge_request
        group_value = group_settings&.allow_overrides_to_approver_list_per_merge_request

        setting(:allow_overrides_to_approver_list_per_merge_request, instance_value, group_value, default: true)
      end

      def retain_approvals_on_push
        instance_value = nil
        group_value = group_settings&.retain_approvals_on_push

        setting(:retain_approvals_on_push, instance_value, group_value, default: true)
      end

      def require_password_to_approve
        instance_value = nil
        group_value = group_settings&.require_password_to_approve

        setting(:require_password_to_approve, instance_value, group_value, default: false)
      end

      private

      def instance_settings
        ::Gitlab::CurrentSettings
      end

      def group_settings
        @group&.group_merge_request_approval_setting
      end

      def setting(name, instance_value, group_value, default:)
        # Setting value should be the instance-level, if set.
        # Otherwise group-level.
        # Finally, fallback on to the default defined here.
        value = instance_value ? !instance_value : group_value

        ComplianceManagement::MergeRequestApprovalSettings::Setting.new(
          value: value.nil? ? default : value,
          locked: instance_value.nil? ? false : instance_value,
          inherited_from: instance_value ? :instance : nil
        )
      end
    end
  end
end
