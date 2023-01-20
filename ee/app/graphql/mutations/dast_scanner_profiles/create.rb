# frozen_string_literal: true

module Mutations
  module DastScannerProfiles
    class Create < BaseMutation
      graphql_name 'DastScannerProfileCreate'

      include FindsProject

      field :id, ::Types::GlobalIDType[::DastScannerProfile],
            null: true,
            description: 'ID of the scanner profile.',
            deprecated: { reason: 'use `dastScannerProfile` field', milestone: '14.10' }

      field :dast_scanner_profile, ::Types::DastScannerProfileType,
            null: true,
            description: 'Created scanner profile.'

      argument :full_path, GraphQL::Types::ID,
               required: true,
               description: 'Project the scanner profile belongs to.'

      argument :profile_name, GraphQL::Types::String,
                required: true,
                description: 'Name of the scanner profile.'

      argument :spider_timeout, GraphQL::Types::Int,
                required: false,
                description: 'Maximum number of minutes allowed for the spider to traverse the site.'

      argument :target_timeout, GraphQL::Types::Int,
                required: false,
                description: 'Maximum number of seconds allowed for the site under test to respond to a request.'

      argument :scan_type, Types::DastScanTypeEnum,
                required: false,
                description: 'Indicates the type of DAST scan that will run. ' \
                'Either a Passive Scan or an Active Scan.',
                default_value: 'passive'

      argument :use_ajax_spider, GraphQL::Types::Boolean,
                required: false,
                description: 'Indicates if the AJAX spider should be used to crawl the target site. ' \
                'True to run the AJAX spider in addition to the traditional spider, and false to run only the traditional spider.',
                default_value: false

      argument :show_debug_messages, GraphQL::Types::Boolean,
                required: false,
                description: 'Indicates if debug messages should be included in DAST console output. ' \
                'True to include the debug messages.',
                default_value: false

      argument :tag_list, [GraphQL::Types::String],
               required: false,
               description: 'Indicates the runner tags associated with the scanner profile.',
               deprecated: { reason: 'Moved to DastProfile', milestone: '15.8' }

      authorize :create_on_demand_dast_scan

      def resolve(**args)
        project = authorized_find!(args.delete(:full_path))

        params = service_params(project, args)

        service = ::AppSec::Dast::ScannerProfiles::CreateService.new(project: project, current_user: current_user, params: params)
        result = service.execute

        if result.success?
          { id: result.payload.to_global_id, dast_scanner_profile: result.payload, errors: [] }
        else
          { errors: result.errors }
        end
      end

      private

      def service_params(project, args)
        args.tap do |values|
          values[:name] = values.delete(:profile_name)
          values.delete(:tag_list) unless Feature.enabled?(:on_demand_scans_runner_tags, project)
        end
      end
    end
  end
end
