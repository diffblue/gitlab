# frozen_string_literal: true

module Users
  module Abuse
    class ProjectsDownloadBanCheckService < BaseService
      def self.execute(user, project)
        return ServiceResponse.success unless user
        return ServiceResponse.success unless project
        return ServiceResponse.success if project.public?

        new(project, user).execute
      end

      def execute
        banned = user_exceeded_download_limit_for_application? || user_exceeded_download_limit_for_namespace?
        banned ? ServiceResponse.error(message: 'User has been banned') : ServiceResponse.success
      end

      alias_method :user, :current_user

      private

      def user_exceeded_download_limit_for_application?
        return false unless License.feature_available?(:git_abuse_rate_limit)
        return false unless Gitlab::CurrentSettings.unique_project_download_limit_enabled?

        result = GitAbuse::ApplicationThrottleService.execute(user, project)

        result[:banned]
      end

      def user_exceeded_download_limit_for_namespace?
        return false unless namespace.group_namespace?
        return false unless namespace.unique_project_download_limit_enabled?

        result = GitAbuse::NamespaceThrottleService.execute(user, project)

        result[:banned]
      end

      def namespace
        project.root_ancestor
      end
    end
  end
end
