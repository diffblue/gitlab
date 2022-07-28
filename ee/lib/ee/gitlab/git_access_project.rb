# frozen_string_literal: true

module EE
  module Gitlab
    module GitAccessProject
      extend ::Gitlab::Utils::Override

      private

      override :check_download_access!
      def check_download_access!
        if user_exceeded_download_limit_for_application? ||
          user_exceeded_download_limit_for_namespace?
          raise ::Gitlab::GitAccess::ForbiddenError, download_forbidden_message
        end

        super
      end

      def user_exceeded_download_limit_for_application?
        return unless user
        return unless ::Feature.enabled?(:git_abuse_rate_limit_feature_flag, user)
        return unless License.feature_available?(:git_abuse_rate_limit)

        result = ::Users::Abuse::ExcessiveProjectsDownloadBanService.execute(user, project)

        result[:banned]
      end

      def user_exceeded_download_limit_for_namespace?
        return unless user

        namespace = project&.root_ancestor
        return unless namespace
        return unless ::Feature.enabled?(:limit_unique_project_downloads_per_namespace_user, namespace)
        return unless License.feature_available?(:unique_project_download_limit)

        result = ::Users::Abuse::GitAbuse::NamespaceThrottleService.execute(project, user)

        result[:banned]
      end
    end
  end
end
