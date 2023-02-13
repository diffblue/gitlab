# frozen_string_literal: true

module Users
  module Abuse
    module GitAbuse
      class BaseThrottleService < ::BaseService
        def self.execute(user, project)
          new(project, user).execute
        end

        def initialize(project, user)
          super
          @users_alerted = rate_limited?(peek: true)
        end

        def execute
          return success(banned: false) unless rate_limited?

          log_rate_limit_exceeded

          alert_users

          success(banned: ban_user!)
        end

        private

        attr_reader :users_alerted

        def success(banned:)
          ServiceResponse.success(payload: { banned: banned })
        end

        def rate_limited?(peek: false)
          ::Gitlab::ApplicationRateLimiter.throttled?(
            key,
            scope: scope,
            resource: project,
            peek: peek,
            threshold: max_project_downloads,
            interval: time_period,
            users_allowlist: allowlist
          )
        end

        def alert_users
          return if users_alerted

          alertlist.each do |user_id|
            Notify.user_auto_banned_email(
              user_id,
              current_user.id,
              max_project_downloads: max_project_downloads,
              within_seconds: time_period,
              auto_ban_enabled: auto_ban_users,
              group: namespace
            ).deliver_later
          end
        end
      end
    end
  end
end
