# frozen_string_literal: true

module Mutations
  module DastScannerProfiles
    class Delete < BaseMutation
      include FindsProject

      graphql_name 'DastScannerProfileDelete'

      ScannerProfileID = ::Types::GlobalIDType[::DastScannerProfile]

      argument :full_path, GraphQL::Types::ID,
                required: true,
                description: 'Full path for the project the scanner profile belongs to.'

      argument :id, ScannerProfileID,
                required: true,
                description: 'ID of the scanner profile to be deleted.'

      authorize :create_on_demand_dast_scan

      def resolve(full_path:, id:)
        # TODO: remove this line once the compatibility layer is removed
        # See: https://gitlab.com/gitlab-org/gitlab/-/issues/257883
        id = ScannerProfileID.coerce_isolated_input(id)

        project = authorized_find!(full_path)

        service = ::AppSec::Dast::ScannerProfiles::DestroyService.new(project, current_user)
        result = service.execute(id: id.model_id)

        if result.success?
          { errors: [] }
        else
          { errors: result.errors }
        end
      end
    end
  end
end
