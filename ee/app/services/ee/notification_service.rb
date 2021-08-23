# frozen_string_literal: true

module EE
  module NotificationService
    include ::Gitlab::Utils::UsageData

    # When we add approvers to a merge request we should send an email to:
    #
    #  * the new approvers
    #
    def add_merge_request_approvers(merge_request, new_approvers, current_user)
      return if merge_request.project.emails_disabled?

      add_mr_approvers_email(merge_request, new_approvers, current_user)
    end

    def approve_mr(merge_request, current_user)
      approve_mr_email(merge_request, merge_request.target_project, current_user)
    end

    def unapprove_mr(merge_request, current_user)
      unapprove_mr_email(merge_request, merge_request.target_project, current_user)
    end

    def mirror_was_hard_failed(project)
      return if project.emails_disabled?

      owners_and_maintainers_without_invites(project).each do |recipient|
        mailer.mirror_was_hard_failed_email(project.id, recipient.user.id).deliver_later
      end
    end

    def mirror_was_disabled(project, deleted_user_name)
      return if project.emails_disabled?

      owners_and_maintainers_without_invites(project).each do |recipient|
        mailer.mirror_was_disabled_email(project.id, recipient.user.id, deleted_user_name).deliver_later
      end
    end

    def new_epic(epic, current_user)
      new_resource_email(epic, current_user, :new_epic_email)
    end

    def close_epic(epic, current_user)
      epic_status_change_email(epic, current_user, 'closed')
    end

    def reopen_epic(epic, current_user)
      epic_status_change_email(epic, current_user, 'reopened')
    end

    def project_mirror_user_changed(new_mirror_user, deleted_user_name, project)
      return if project.emails_disabled?

      mailer.project_mirror_user_changed_email(new_mirror_user.id, deleted_user_name, project.id).deliver_later
    end

    def removed_iteration_issue(issue, current_user)
      removed_iteration_resource_email(issue, current_user)
    end

    def changed_iteration_issue(issue, new_iteration, current_user)
      changed_iteration_resource_email(issue, new_iteration, current_user)
    end

    def new_group_member_with_confirmation(group_member)
      mailer.provisioned_member_access_granted_email(group_member.id).deliver_later
    end

    def notify_oncall_users_of_alert(users, alert)
      track_usage_event(:i_incident_management_oncall_notification_sent, users.map(&:id))

      users.each do |user|
        mailer.prometheus_alert_fired_email(alert.project, user, alert).deliver_later
      end
    end

    def oncall_user_removed(rotation, user, async = true)
      project_owners_and_participants(rotation, user).each do |recipient|
        email = mailer.user_removed_from_rotation_email(user, rotation, [recipient])
        async ? email.deliver_later : email.deliver_now
      end
    end

    private

    def project_owners_and_participants(rotation, user)
      project = rotation.project

      owners = project.owner.is_a?(Group) ? project.owner.owners : [project.owner]
      member_owners = project.members.owners

      (owners + member_owners + rotation.participants.map(&:user) - [user]).compact.uniq
    end

    def add_mr_approvers_email(merge_request, approvers, current_user)
      approvers.each do |approver|
        mailer.add_merge_request_approver_email(approver.id, merge_request.id, current_user.id).deliver_later
      end
    end

    def approve_mr_email(merge_request, project, current_user)
      recipients = ::NotificationRecipients::BuildService.build_recipients(merge_request, current_user, action: 'approve')

      recipients.each do |recipient|
        mailer.approved_merge_request_email(recipient.user.id, merge_request.id, current_user.id).deliver_later
      end
    end

    def unapprove_mr_email(merge_request, project, current_user)
      recipients = ::NotificationRecipients::BuildService.build_recipients(merge_request, current_user, action: 'unapprove')

      recipients.each do |recipient|
        mailer.unapproved_merge_request_email(recipient.user.id, merge_request.id, current_user.id).deliver_later
      end
    end

    def removed_iteration_resource_email(target, current_user)
      recipients = ::NotificationRecipients::BuildService.build_recipients(
        target,
        current_user,
        action: 'removed_iteration'
      )

      recipients.each do |recipient|
        mailer.removed_iteration_issue_email(recipient.user.id, target.id, current_user.id).deliver_later
      end
    end

    def changed_iteration_resource_email(target, iteration, current_user)
      recipients = ::NotificationRecipients::BuildService.build_recipients(
        target,
        current_user,
        action: 'changed_iteration'
      )

      recipients.each do |recipient|
        mailer.changed_iteration_issue_email(recipient.user.id, target.id, iteration, current_user.id).deliver_later
      end
    end

    def epic_status_change_email(target, current_user, status)
      action = status == 'reopened' ? 'reopen' : 'close'

      recipients = ::NotificationRecipients::BuildService.build_recipients(
        target,
        current_user,
        action: action
      )

      recipients.each do |recipient|
        mailer.epic_status_changed_email(
          recipient.user.id, target.id, status, current_user.id, recipient.reason)
          .deliver_later
      end
    end
  end
end
