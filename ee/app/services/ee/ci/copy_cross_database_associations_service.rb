# frozen_string_literal: true

module EE
  module Ci
    module CopyCrossDatabaseAssociationsService
      extend ::Gitlab::Utils::Override

      override :execute
      def execute(old_build, new_build)
        return ServiceResponse.success unless old_build.instance_of?(::Ci::Build)

        response = AppSec::Dast::Builds::AssociateService.new(
          ci_build_id: new_build.id,
          dast_site_profile_id: old_build.dast_site_profile&.id,
          dast_scanner_profile_id: old_build.dast_scanner_profile&.id
        ).execute

        response.tap do
          new_build.reset.drop! if response.error?
        end
      end
    end
  end
end
