# frozen_string_literal: true

module EE
  module Projects
    module InactiveProjectsDeletionCronWorker
      extend ::Gitlab::Utils::Override

      override :delete_project
      def delete_project(project, user)
        return super unless License.feature_available?(:adjourned_deletion_for_projects_and_groups)
        # Can't use `project.adjourned_deletion?` see https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85689#note_943072034
        return super unless project.adjourned_deletion_configured?

        ::Projects::MarkForDeletionService.new(project, user, {}).execute
      end

      override :send_deletion_warning_email?
      def send_deletion_warning_email?(deletion_warning_email_sent_on, project)
        # Can't use `project.marked_for_deletion?`, see https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85689#note_943072064
        return false if project.marked_for_deletion_at?

        super
      end

      override :send_notification
      def send_notification(project, user)
        super

        audit_context = {
          name: 'inactive_project_scheduled_for_deletion',
          author: user,
          scope: project,
          target: project,
          message: "Project is scheduled to be deleted on #{deletion_date} due to inactivity."
        }

        ::Gitlab::Audit::Auditor.audit(audit_context)
      end
    end
  end
end
