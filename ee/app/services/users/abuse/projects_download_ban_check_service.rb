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
        return false unless ::Feature.enabled?(:git_abuse_rate_limit_feature_flag, user)
        return false unless License.feature_available?(:git_abuse_rate_limit)

        result = ExcessiveProjectsDownloadBanService.execute(user, project)

        result[:banned]
      end

      def user_exceeded_download_limit_for_namespace?
        return false unless ::Feature.enabled?(:limit_unique_project_downloads_per_namespace_user, namespace)
        return false unless License.feature_available?(:unique_project_download_limit)

        result = GitAbuse::NamespaceThrottleService.execute(project, user)

        result[:banned]
      end

      def namespace
        project.root_ancestor
      end
    end
  end
end
