# frozen_string_literal: true

module Mutations
  module DastSiteProfiles
    class Delete < BaseMutation
      graphql_name 'DastSiteProfileDelete'

      argument :full_path, GraphQL::Types::ID,
               required: true,
               description: 'The project the site profile belongs to.'

      argument :id, ::Types::GlobalIDType[::DastSiteProfile],
               required: true,
               description: 'ID of the site profile to be deleted.'

      authorize :create_on_demand_dast_scan

      def resolve(full_path:, id:)
        project = authorized_find!(full_path)
        # TODO: remove explicit coercion once compatibility layer is removed
        # See: https://gitlab.com/gitlab-org/gitlab/-/issues/257883
        id = ::Types::GlobalIDType[::DastSiteProfile].coerce_isolated_input(id)

        service = ::AppSec::Dast::SiteProfiles::DestroyService.new(project, current_user)
        result = service.execute(id: id.model_id)

        return { errors: result.errors } unless result.success?

        { errors: [] }
      end

      private

      def find_object(full_path)
        Project.find_by_full_path(full_path)
      end
    end
  end
end
