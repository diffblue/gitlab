# frozen_string_literal: true

module Types
  module Dast
    class ProfileType < BaseObject
      graphql_name 'DastProfile'
      description 'Represents a DAST Profile'

      connection_type_class(Types::CountableConnectionType)

      authorize :read_on_demand_dast_scan

      field :id, ::Types::GlobalIDType[::Dast::Profile],
        null: false, description: 'ID of the profile.'

      field :name, GraphQL::Types::String,
        null: true, description: 'Name of the profile.'

      field :description, GraphQL::Types::String,
        null: true, description: 'Description of the scan.'

      field :dast_site_profile, DastSiteProfileType,
        null: true, description: 'Associated site profile.'

      field :dast_scanner_profile, DastScannerProfileType,
        null: true, description: 'Associated scanner profile.'

      field :dast_profile_schedule, ::Types::Dast::ProfileScheduleType,
        null: true, method: :dast_profile_schedule, description: 'Associated profile schedule.'

      field :branch, Dast::ProfileBranchType,
        null: true, calls_gitaly: true, description: 'Associated branch.'

      field :edit_path, GraphQL::Types::String,
        null: true, description: 'Relative web path to the edit page of a profile.'

      field :dast_pre_scan_verification,
            ::Types::Dast::PreScanVerificationType,
            null: true,
            description: 'DAST Pre Scan Verification associated with the site profile. Will always return `null` ' \
                         'if `dast_on_demand_scans_scheduler` feature flag is disabled.'

      field :tag_list, [GraphQL::Types::String],
            null: true, description: 'Runner tags associated with the profile.'

      def edit_path
        Gitlab::Routing.url_helpers.edit_project_on_demand_scan_path(object.project, object)
      end

      def dast_pre_scan_verification
        return unless Feature.enabled?(:dast_pre_scan_verification, object.project)

        object.dast_pre_scan_verification
      end
    end
  end
end
