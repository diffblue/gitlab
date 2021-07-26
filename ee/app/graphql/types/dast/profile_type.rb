# frozen_string_literal: true

module Types
  module Dast
    class ProfileType < BaseObject
      graphql_name 'DastProfile'
      description 'Represents a DAST Profile'

      authorize :read_on_demand_scans

      field :id, ::Types::GlobalIDType[::Dast::Profile], null: false,
            description: 'ID of the profile.'

      field :name, GraphQL::Types::String, null: true,
            description: 'The name of the profile.'

      field :description, GraphQL::Types::String, null: true,
            description: 'The description of the scan.'

      field :dast_site_profile, DastSiteProfileType, null: true,
            description: 'The associated site profile.'

      field :dast_scanner_profile, DastScannerProfileType, null: true,
            description: 'The associated scanner profile.'

      field :branch, Dast::ProfileBranchType, null: true,
            description: 'The associated branch.',
            calls_gitaly: true

      field :edit_path, GraphQL::Types::String, null: true,
            description: 'Relative web path to the edit page of a profile.'

      def edit_path
        Gitlab::Routing.url_helpers.edit_project_on_demand_scan_path(object.project, object)
      end
    end
  end
end
