# frozen_string_literal: true

module Users
  module Abuse
    module GitAbuse
      class ApplicationThrottleService < BaseThrottleService
        private

        def log_rate_limit_exceeded
          log_info(
            message: "User exceeded max projects download within set time period for application",
            username: current_user.username,
            max_project_downloads: max_project_downloads,
            time_period_s: time_period
          )
        end

        def ban_user!
          return false unless auto_ban_users
          return false if current_user.can_admin_all_resources?

          begin
            result = current_user.ban!

            log_info(
              message: "Application-level user ban",
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

        def key
          :unique_project_downloads_for_application
        end

        def scope
          current_user
        end

        def namespace
          nil
        end

        def max_project_downloads
          @max_project_downloads ||= settings.max_number_of_repository_downloads
        end

        def time_period
          @time_period ||= settings.max_number_of_repository_downloads_within_time_period
        end

        def allowlist
          @allowlist ||= settings.git_rate_limit_users_allowlist
        end

        def alertlist
          @alertlist ||= settings.git_rate_limit_users_alertlist
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
end
