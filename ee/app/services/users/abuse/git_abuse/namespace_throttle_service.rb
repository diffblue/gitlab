# frozen_string_literal: true

module Users
  module Abuse
    module GitAbuse
      class NamespaceThrottleService < BaseService
        def self.execute(project, user)
          new(project, user).execute
        end

        def initialize(project, user)
          super
          @admins_alerted = rate_limited?(peek: true)
        end

        def execute
          return { banned: false } unless rate_limited?

          log_info(
            message: "User exceeded max projects download within set time period for namespace",
            username: current_user.username,
            max_project_downloads: max_project_downloads,
            time_period_s: time_period,
            namespace_id: namespace.id
          )

          alert_admins

          { banned: ban_user! }
        end

        private

        attr_reader :admins_alerted

        def rate_limited?(peek: false)
          ::Gitlab::ApplicationRateLimiter.throttled?(
            :unique_project_downloads_for_namespace,
            scope: [current_user, namespace],
            resource: project,
            peek: peek,
            threshold: max_project_downloads,
            interval: time_period,
            users_allowlist: allowlist
          )
        end

        def user_owns_namespace?
          namespace&.owned_by?(current_user)
        end

        def ban_user!
          return false unless auto_ban_users
          return false if user_owns_namespace?

          result = ::Users::Abuse::NamespaceBans::CreateService.new(namespace: namespace, user: current_user).execute
          banned = result[:status] == :success

          if banned
            log_info(
              message: "Namespace-level user ban",
              username: current_user.username,
              email: current_user.email,
              namespace_id: namespace.id,
              ban_by: self.class.name
            )
          end

          banned || current_user.banned_from_namespace?(namespace)
        end

        def alert_admins
          return if admins_alerted

          admins.each do |admin|
            next unless admin.active?

            Notify.user_auto_banned_email(
              admin.id,
              current_user.id,
              max_project_downloads: max_project_downloads,
              within_seconds: time_period,
              auto_ban_enabled: auto_ban_users,
              group: namespace
            ).deliver_later
          end
        end

        def namespace
          @namespace ||= project&.root_ancestor
        end

        def namespace_settings
          @namespace_settings ||= namespace&.namespace_settings
        end

        def admins
          @admins ||= namespace&.owners
        end

        def max_project_downloads
          @max_project_downloads ||= namespace_settings&.unique_project_download_limit
        end

        def time_period
          @time_period ||= namespace_settings&.unique_project_download_limit_interval_in_seconds
        end

        def allowlist
          @allowlist ||= namespace_settings&.unique_project_download_limit_allowlist
        end

        def auto_ban_users
          @auto_ban_users ||= namespace_settings&.auto_ban_user_on_excessive_projects_download
        end
      end
    end
  end
end
