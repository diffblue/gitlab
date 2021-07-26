# frozen_string_literal: true

module Types
  class DastScannerProfileType < BaseObject
    graphql_name 'DastScannerProfile'
    description 'Represents a DAST scanner profile'

    authorize :read_on_demand_scans

    field :id, ::Types::GlobalIDType[::DastScannerProfile], null: false,
          description: 'ID of the DAST scanner profile.'

    field :profile_name, GraphQL::Types::String, null: true,
          description: 'Name of the DAST scanner profile.',
          method: :name

    field :spider_timeout, GraphQL::Types::Int, null: true,
          description: 'The maximum number of minutes allowed for the spider to traverse the site.'

    field :target_timeout, GraphQL::Types::Int, null: true,
          description: 'The maximum number of seconds allowed for the site under test to respond to a request.'

    field :scan_type, Types::DastScanTypeEnum, null: true,
          description: 'Indicates the type of DAST scan that will run. ' \
          'Either a Passive Scan or an Active Scan.'

    field :use_ajax_spider, GraphQL::Types::Boolean, null: false,
          description: 'Indicates if the AJAX spider should be used to crawl the target site. ' \
          'True to run the AJAX spider in addition to the traditional spider, and false to run only the traditional spider.'

    field :show_debug_messages, GraphQL::Types::Boolean, null: false,
          description: 'Indicates if debug messages should be included in DAST console output. ' \
          'True to include the debug messages.'

    field :edit_path, GraphQL::Types::String, null: true,
          description: 'Relative web path to the edit page of a scanner profile.'

    field :referenced_in_security_policies, [GraphQL::Types::String], null: true,
          calls_gitaly: true,
          description: 'List of security policy names that are referencing given project.'

    def edit_path
      Rails.application.routes.url_helpers.edit_project_security_configuration_dast_scans_dast_scanner_profile_path(object.project, object)
    end

    def referenced_in_security_policies
      ::Gitlab::Graphql::Aggregations::SecurityOrchestrationPolicies::LazyDastProfileAggregate.new(
        context,
        object
      )
    end
  end
end
