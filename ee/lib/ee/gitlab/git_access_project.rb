# frozen_string_literal: true

module EE
  module Gitlab
    module GitAccessProject
      extend ::Gitlab::Utils::Override

      EE_ERROR_MESSAGES = {
        namespace_forbidden: 'You are not allowed to access projects in this namespace.'
      }.freeze

      private

      override :check_download_access!
      def check_download_access!
        result = ::Users::Abuse::ProjectsDownloadBanCheckService.execute(user, project)
        raise ::Gitlab::GitAccess::ForbiddenError, download_forbidden_message if result.error?

        super
      end

      override :check_namespace!
      def check_namespace!
        unless allowed_access_namespace?
          raise ::Gitlab::GitAccess::ForbiddenError, EE_ERROR_MESSAGES[:namespace_forbidden]
        end

        super
      end

      def allowed_access_namespace?
        return true unless namespace&.licensed_feature_available?(:ssh_certificates)
        return true if allowed_namespace_path.blank?

        allowed_namespace = ::Namespace.find_by_full_path(allowed_namespace_path)
        allowed_namespace.present? && namespace.root_ancestor.id == allowed_namespace.id
      end
    end
  end
end
