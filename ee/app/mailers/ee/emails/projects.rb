# frozen_string_literal: true

module EE
  module Emails
    module Projects
      def mirror_was_hard_failed_email(project_id, user_id)
        @project = ::Project.find(project_id)
        user = ::User.find(user_id)

        mail_with_locale(
          to: user.notification_email_for(@project.group),
          subject: subject('Repository mirroring paused')
        )
      end

      def mirror_was_disabled_email(project_id, user_id, deleted_user_name)
        @project = ::Project.find(project_id)
        user = ::User.find_by_id(user_id)
        @deleted_user_name = deleted_user_name

        return unless user

        mail_with_locale(
          to: user.notification_email_for(@project.group),
          subject: subject('Repository mirroring disabled')
        )
      end

      def project_mirror_user_changed_email(new_mirror_user_id, deleted_user_name, project_id)
        @project = ::Project.find(project_id)
        @deleted_user_name = deleted_user_name
        user = ::User.find(new_mirror_user_id)

        mail_with_locale(
          to: user.notification_email_for(@project.group),
          subject: subject('Mirror user changed')
        )
      end

      def user_escalation_rule_deleted_email(user, project, rules, recipient)
        @user = user
        @project = project
        @rules = rules

        email_with_layout(
          to: recipient.notification_email_for(@project.group),
          subject: subject('User removed from escalation policy'))
      end

      def incident_escalation_fired_email(project, user, issue)
        @project = project
        @incident = issue.present
        @escalation_status = issue.incident_management_issuable_escalation_status

        add_project_headers
        headers['X-GitLab-NotificationReason'] = "incident_#{@escalation_status.status_name}"
        add_incident_headers

        subject_text = "Incident: #{@incident.title}"
        mail_with_locale(to: user.notification_email_for(@project.group), subject: subject(subject_text))
      end
    end
  end
end
