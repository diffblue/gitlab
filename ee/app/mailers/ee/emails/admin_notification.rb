# frozen_string_literal: true

module EE
  module Emails
    module AdminNotification
      def user_auto_banned_email(
        alerted_user_id, user_id, max_project_downloads:, within_seconds:, auto_ban_enabled:, group: nil
      )
        alerted_user = ::User.find_by_id(alerted_user_id)
        return unless alerted_user.present?

        @user = ::User.find(user_id)
        @max_project_downloads = max_project_downloads
        @within_seconds = within_seconds
        @within_minutes = within_seconds / 60
        @auto_ban_enabled = auto_ban_enabled

        if group.present?
          @ban_scope = _('your group (%{group_name})' % { group_name: group.name })
          @settings_page_url = group_settings_reporting_url(group)
          @banned_page_url = group_group_members_url(group, tab: 'banned')
        else
          @ban_scope = _('your GitLab instance')
          @settings_page_url = reporting_admin_application_settings_url
          @banned_page_url = admin_users_url(filter: 'banned')
        end

        ::Gitlab::I18n.with_locale(alerted_user.preferred_language) do
          email_with_layout(
            to: alerted_user.notification_email_or_default,
            subject: subject(_("We've detected unusual activity")))
        end
      end
    end
  end
end
