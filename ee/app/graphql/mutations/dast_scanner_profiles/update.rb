# frozen_string_literal: true

module Mutations
  module DastScannerProfiles
    class Update < BaseMutation
      graphql_name 'DastScannerProfileUpdate'

      include FindsProject

      ScannerProfileID = ::Types::GlobalIDType[::DastScannerProfile]

      field :id, ScannerProfileID,
            null: true,
            description: 'ID of the scanner profile.'

      argument :full_path, GraphQL::Types::ID,
               required: false,
               deprecated: { reason: 'Full path not required to qualify Global ID', milestone: '14.5' },
               description: 'Project the scanner profile belongs to.'

      argument :id, ::Types::GlobalIDType[::DastScannerProfile],
               required: true,
               description: 'ID of the scanner profile to be updated.'

      argument :profile_name, GraphQL::Types::String,
               required: true,
               description: 'Name of the scanner profile.'

      argument :spider_timeout, GraphQL::Types::Int,
               required: true,
               description: 'Maximum number of minutes allowed for the spider to traverse the site.'

      argument :target_timeout, GraphQL::Types::Int,
               required: true,
               description: 'Maximum number of seconds allowed for the site under test to respond to a request.'

      argument :scan_type, Types::DastScanTypeEnum,
               required: false,
               description: 'Indicates the type of DAST scan that will run. ' \
                            'Either a Passive Scan or an Active Scan.'

      argument :use_ajax_spider, GraphQL::Types::Boolean,
               required: false,
               description: 'Indicates if the AJAX spider should be used to crawl the target site. ' \
                            'True to run the AJAX spider in addition to the traditional spider, and false to run only the traditional spider.'

      argument :show_debug_messages, GraphQL::Types::Boolean,
               required: false,
               description: 'Indicates if debug messages should be included in DAST console output. ' \
                            'True to include the debug messages.'

      authorize :create_on_demand_dast_scan

      def resolve(id:, full_path: nil, **service_args)
        dast_scanner_profile = authorized_find!(id)

        service = ::AppSec::Dast::ScannerProfiles::UpdateService.new(dast_scanner_profile.project, current_user)
        result = service.execute(**service_args, id: dast_scanner_profile.id)

        if result.success?
          { id: result.payload.to_global_id, errors: [] }
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
