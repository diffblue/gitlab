# frozen_string_literal: true

module Mutations
  module DastOnDemandScans
    class Create < BaseMutation
      include FindsProject

      InvalidGlobalID = Class.new(StandardError)

      graphql_name 'DastOnDemandScanCreate'

      field :pipeline_url, GraphQL::Types::String,
            null: true,
            description: 'URL of the pipeline that was created.'

      argument :full_path, GraphQL::Types::ID,
               required: true,
               description: 'The project the site profile belongs to.'

      argument :dast_site_profile_id, ::Types::GlobalIDType[::DastSiteProfile],
               required: true,
               description: 'ID of the site profile to be used for the scan.'

      argument :dast_scanner_profile_id, ::Types::GlobalIDType[::DastScannerProfile],
               required: false,
               description: 'ID of the scanner profile to be used for the scan.'

      authorize :create_on_demand_dast_scan

      def resolve(full_path:, dast_site_profile_id:, **args)
        project = authorized_find!(full_path)

        dast_site_profile = find_dast_site_profile(project, dast_site_profile_id)
        dast_scanner_profile = find_dast_scanner_profile(project, args[:dast_scanner_profile_id])

        response = create_on_demand_dast_scan(project, dast_site_profile, dast_scanner_profile)

        return { errors: response.errors } if response.error?

        { errors: [], pipeline_url: response.payload.fetch(:pipeline_url) }
      end

      private

      # rubocop: disable CodeReuse/ActiveRecord
      def find_dast_site_profile(project, dast_site_profile_id)
        # TODO: remove explicit coercion once compatibility layer is removed
        # See: https://gitlab.com/gitlab-org/gitlab/-/issues/257883
        dast_site_profile_id = ::Types::GlobalIDType[::DastSiteProfile].coerce_isolated_input(dast_site_profile_id)

        DastSiteProfilesFinder.new(project_id: project.id, id: dast_site_profile_id.model_id)
          .execute
          .first!
      end
      # rubocop: enable CodeReuse/ActiveRecord

      # rubocop: disable CodeReuse/ActiveRecord
      def find_dast_scanner_profile(project, dast_scanner_profile_id)
        return unless dast_scanner_profile_id

        # TODO: remove explicit coercion once compatibility layer is removed
        # See: https://gitlab.com/gitlab-org/gitlab/-/issues/257883
        dast_scanner_profile_id = ::Types::GlobalIDType[::DastScannerProfile]
                                    .coerce_isolated_input(dast_scanner_profile_id)

        DastScannerProfilesFinder.new(
          project_ids: [project.id],
          ids: [dast_scanner_profile_id.model_id]
        ).execute.first!
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def create_on_demand_dast_scan(project, dast_site_profile, dast_scanner_profile)
        ::DastOnDemandScans::CreateService.new(
          container: project,
          current_user: current_user,
          params: {
            dast_site_profile: dast_site_profile,
            dast_scanner_profile: dast_scanner_profile
          }
        ).execute
      end
    end
  end
end
