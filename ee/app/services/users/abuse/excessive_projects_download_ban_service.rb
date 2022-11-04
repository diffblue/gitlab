# frozen_string_literal: true

module Users
  module Abuse
    class ExcessiveProjectsDownloadBanService < BaseService
      def self.execute(user, project)
        new(project, user).execute
      end

      def initialize(project, user)
        super
        @admins_alerted = rate_limited?(peek: true)
      end

      def execute
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

      attr_reader :admins_alerted

      def rate_limited?(peek: false)
        ::Gitlab::ApplicationRateLimiter.throttled?(
          :unique_project_downloads_for_application,
          scope: current_user,
          resource: project,
          peek: peek,
          users_allowlist: users_allowlist
        )
      end

      def ban_user!
        return false unless auto_ban_users

        begin
          result = current_user.ban!

          log_info(
            message: "User ban",
            user: current_user.username,
            email: current_user.email,
            ban_by: self.class.name
          )

          result
        rescue StateMachines::InvalidTransition => e
          # If the user is not in a valid state to be banned (e.g. already banned)
          # we'll log the event, ignore the exception, and proceed as normal.
          log_info(
            message: "Invalid transition when banning: #{e.message}",
            user: current_user.username,
            email: current_user.email,
            ban_by: self.class.name
          )

          true
        end
      end

      def alert_admins
        return if admins_alerted

        User.admins.active.each do |admin|
          Notify.user_auto_banned_email(
            admin.id,
            current_user.id,
            max_project_downloads: max_project_downloads,
            within_seconds: time_period,
            auto_ban_enabled: auto_ban_users
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

      def auto_ban_users
        @auto_ban_users ||= settings.auto_ban_user_on_excessive_projects_download
      end

      def settings
        @settings ||= Gitlab::CurrentSettings.current_application_settings
      end
    end
  end
end
