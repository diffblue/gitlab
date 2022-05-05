# frozen_string_literal: true

module EE
  module Projects
    module InactiveProjectsDeletionCronWorker
      extend ::Gitlab::Utils::Override

      override :delete_project
      def delete_project(project, user)
        return super unless License.feature_available?(:adjourned_deletion_for_projects_and_groups)
        return super unless project.adjourned_deletion_configured?

        ::Projects::MarkForDeletionService.new(project, user, {}).execute
      end

      override :send_deletion_warning_email?
      def send_deletion_warning_email?(deletion_warning_email_sent_on, project)
        return false if project.marked_for_deletion_at?

        super
      end

      override :send_notification
      def send_notification(delay, project, user)
        super

        ::AuditEventService.new(
          user,
          project,
          action: :custom,
          custom_message: "Project is scheduled to be deleted on #{deletion_date} due to inactivity."
        ).for_project.security_event
      end
    end
  end
end
