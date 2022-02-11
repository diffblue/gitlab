# frozen_string_literal: true

module Mutations
  module DastScannerProfiles
    class Delete < BaseMutation
      graphql_name 'DastScannerProfileDelete'

      include FindsProject

      ScannerProfileID = ::Types::GlobalIDType[::DastScannerProfile]

      argument :full_path, GraphQL::Types::ID,
               required: false,
               deprecated: { reason: 'Full path not required to qualify Global ID', milestone: '14.5' },
               description: 'Full path for the project the scanner profile belongs to.'

      argument :id, ScannerProfileID,
               required: true,
               description: 'ID of the scanner profile to be deleted.'

      authorize :create_on_demand_dast_scan

      def resolve(id:, full_path: nil)
        dast_scanner_profile = authorized_find!(id)

        service = ::AppSec::Dast::ScannerProfiles::DestroyService.new(dast_scanner_profile.project, current_user)
        result = service.execute(id: dast_scanner_profile.id)

        if result.success?
          { errors: [] }
        else
          { errors: result.errors }
        end
      end

      private

      def find_object(id)
        # TODO: remove this line when the compatibility layer is removed
        # See: https://gitlab.com/gitlab-org/gitlab/-/issues/257883
        id = ScannerProfileID.coerce_isolated_input(id)

        GitlabSchema.find_by_gid(id)
      end
    end
  end
end
