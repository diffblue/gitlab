# frozen_string_literal: true

module Users
  module Abuse
    class ExcessiveProjectsDownloadBanService < BaseService
      def self.execute(user, project)
        new(project, user).execute
      end

      def execute
        check_admins_alerted

        if rate_limited?
          log_info(
            message: "User exceeded max projects download within set time period",
            username: current_user.username,
            max_project_downloads: max_project_downloads,
            time_period_s: time_period
          )

          alert_admins

          return { banned: ban_user! }
        end

        { banned: false }
      end

      private

      attr_accessor :admins_alerted

      def rate_limited?(peek: false)
        ::Gitlab::ApplicationRateLimiter.throttled?(
          :unique_project_downloads,
          scope: current_user,
          resource: project,
          peek: peek,
          users_allowlist: users_allowlist
        )
      end

      def check_admins_alerted
        # If user was rate limited before then we know that admins have already
        # been alerted
        @admins_alerted = rate_limited?(peek: true)
      end

      def ban_user!
        return false unless ::Feature.enabled?(:auto_ban_user_on_excessive_projects_download)

        result = current_user.ban!

        log_info(
          message: "User ban",
          user: "#{current_user.username}",
          email: "#{current_user.email}",
          ban_by: "#{self.class.name}"
        )

        result
      rescue StateMachines::InvalidTransition => e
        # If the user is not in a valid state to be banned (e.g. already banned)
        # we'll log the event, ignore the exception, and proceed as normal.
        log_info(
          message: "Invalid transition when banning: #{e.message}",
          user: current_user.username,
          email: "#{current_user.email}",
          ban_by: "#{self.class.name}"
        )

        true
      end

      def alert_admins
        return if admins_alerted

        User.admins.each do |admin|
          Notify.user_auto_banned_email(
            admin.id,
            current_user.id,
            max_project_downloads: max_project_downloads,
            within_seconds: time_period
          ).deliver_later
        end
      end

      def max_project_downloads
        @max_project_downloads ||= settings.max_number_of_repository_downloads
      end

      def time_period
        @time_period ||= settings.max_number_of_repository_downloads_within_time_period
      end

      def users_allowlist
        @git_rate_limit_users_allowlist ||= settings.git_rate_limit_users_allowlist
      end

      def settings
        @settings ||= Gitlab::CurrentSettings.current_application_settings
      end
    end
  end
end
