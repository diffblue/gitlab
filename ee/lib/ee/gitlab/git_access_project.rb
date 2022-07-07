# frozen_string_literal: true

module EE
  module Gitlab
    module GitAccessProject
      extend ::Gitlab::Utils::Override

      override :size_checker
      def size_checker
        root_namespace = container.namespace.root_ancestor
        if ::EE::Gitlab::Namespaces::Storage::Enforcement.enforce_limit?(root_namespace)
          ::EE::Namespace::RootStorageSize.new(root_namespace)
        else
          container.repository_size_checker
        end
      end

      private

      override :check_download_access!
      def check_download_access!
        if user_exceeded_download_limit?
          raise ::Gitlab::GitAccess::ForbiddenError, download_forbidden_message
        end

        super
      end

      def user_exceeded_download_limit?
        return unless user
        return unless ::Feature.enabled?(:git_abuse_rate_limit_feature_flag, user)
        return unless License.feature_available?(:git_abuse_rate_limit)

        result = ::Users::Abuse::ExcessiveProjectsDownloadBanService.execute(user, project)

        result[:banned]
      end
    end
  end
end
