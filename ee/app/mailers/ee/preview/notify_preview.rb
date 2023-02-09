# frozen_string_literal: true

module EE
  module Preview
    module NotifyPreview
      FREE_USER_CAP_OVERLIMIT_CHECKED_AT = "2022-11-07 14:33:44 UTC"
      extend ActiveSupport::Concern

      # We need to define the methods on the prepender directly because:
      # https://github.com/rails/rails/blob/3faf7485623da55215d6d7f3dcb2eed92c59c699/actionmailer/lib/action_mailer/preview.rb#L73
      prepended do
        def add_merge_request_approver_email
          ::Notify.add_merge_request_approver_email(user.id, merge_request.id, user.id).message
        end

        def approved_merge_request_email
          ::Notify.approved_merge_request_email(user.id, merge_request.id, approver.id).message
        end

        def unapproved_merge_request_email
          ::Notify.unapproved_merge_request_email(user.id, merge_request.id, approver.id).message
        end

        def mirror_was_hard_failed_email
          ::Notify.mirror_was_hard_failed_email(project.id, user.id).message
        end

        def mirror_was_disabled_email
          ::Notify.mirror_was_disabled_email(project.id, user.id, 'deleted_user_name').message
        end

        def project_mirror_user_changed_email
          ::Notify.project_mirror_user_changed_email(user.id, 'deleted_user_name', project.id).message
        end

        def send_admin_notification
          ::Notify.send_admin_notification(user.id, 'Email subject from admin', 'Email body from admin').message
        end

        def send_unsubscribed_notification
          ::Notify.send_unsubscribed_notification(user.id).message
        end

        def import_requirements_csv_email
          ::Notify.import_requirements_csv_email(user.id, project.id, { success: 3, errors: [5, 6, 7], valid_file: true })
        end

        def requirements_csv_email
          ::Notify.requirements_csv_email(
            user, project, 'requirement1,requirement2,requirement3',
            { truncated: false, rows_expected: 3, rows_written: 3 }
          ).message
        end

        def new_group_member_with_confirmation_email
          ::Notify.provisioned_member_access_granted_email(member.id).message
        end

        def new_epic_email
          ::Notify.new_epic_email(user.id, epic.id).message
        end

        def merge_commits_csv_email
          ::Notify.merge_commits_csv_email(
            user,
            project.group,
            'one,two,three',
            'filename.csv'
          ).message
        end

        def user_auto_banned_instance_email
          ::Notify.user_auto_banned_email(user.id, user.id, max_project_downloads: 5, within_seconds: 600, auto_ban_enabled: true).message
        end

        def user_auto_banned_namespace_email
          ::Notify.user_auto_banned_email(user.id, user.id, max_project_downloads: 5, within_seconds: 600, auto_ban_enabled: true, group: group).message
        end

        def user_cap_reached
          ::Notify.user_cap_reached(user.id).message
        end

        def over_free_user_limit_email
          ::Notify.over_free_user_limit_email(user, group, FREE_USER_CAP_OVERLIMIT_CHECKED_AT).message
        end

        def confirmation_instructions_email
          ::Notify.confirmation_instructions_email(user.email, token: '123456').message
        end

        def abandoned_trial_notification
          ::Notify.abandoned_trial_notification(user.id).message
        end
      end

      private

      def approver
        @user ||= ::User.first
      end

      def epic
        @epic ||= project.group.epics.first
      end
    end
  end
end
