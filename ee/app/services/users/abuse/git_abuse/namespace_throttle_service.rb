# frozen_string_literal: true

module Users
  module Abuse
    module GitAbuse
      class NamespaceThrottleService < BaseThrottleService
        private

        def log_rate_limit_exceeded
          log_info(
            message: "User exceeded max projects download within set time period for namespace",
            username: current_user.username,
            max_project_downloads: max_project_downloads,
            time_period_s: time_period,
            namespace_id: namespace.id
          )
        end

        def user_owns_namespace?
          namespace&.owned_by?(current_user)
        end

        def ban_user!
          return false unless auto_ban_users
          return false if user_owns_namespace?

          result = ::Users::Abuse::NamespaceBans::CreateService.new(namespace: namespace, user: current_user).execute
          banned = result.success?

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

        def key
          :unique_project_downloads_for_namespace
        end

        def scope
          [current_user, namespace]
        end

        def namespace
          @namespace ||= project&.root_ancestor
        end

        def namespace_settings
          @namespace_settings ||= namespace&.namespace_settings
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

        def alertlist
          @alertlist ||= namespace_settings&.unique_project_download_limit_alertlist
        end

        def auto_ban_users
          @auto_ban_users ||= namespace_settings&.auto_ban_user_on_excessive_projects_download
        end
      end
    end
  end
end
