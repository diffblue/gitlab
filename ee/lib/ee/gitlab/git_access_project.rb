# frozen_string_literal: true

module EE
  module Gitlab
    module GitAccessProject
      extend ::Gitlab::Utils::Override

      private

      override :check_download_access!
      def check_download_access!
        result = ::Users::Abuse::ProjectsDownloadBanCheckService.execute(user, project)
        raise ::Gitlab::GitAccess::ForbiddenError, download_forbidden_message if result.error?

        super
      end
    end
  end
end
