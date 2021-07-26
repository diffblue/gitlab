# frozen_string_literal: true

module Types
  class DastSiteProfileType < BaseObject
    REDACTED_REQUEST_HEADERS = '[Redacted]'

    graphql_name 'DastSiteProfile'
    description 'Represents a DAST Site Profile'

    present_using ::Dast::SiteProfilePresenter

    authorize :read_on_demand_scans

    expose_permissions Types::PermissionTypes::DastSiteProfile

    field :id, ::Types::GlobalIDType[::DastSiteProfile], null: false,
          description: 'ID of the site profile.'

    field :profile_name, GraphQL::Types::String, null: true,
          description: 'The name of the site profile.',
          method: :name

    field :target_url, GraphQL::Types::String, null: true,
          description: 'The URL of the target to be scanned.'

    field :target_type, Types::DastTargetTypeEnum, null: true,
          description: 'The type of target to be scanned.'

    field :edit_path, GraphQL::Types::String, null: true,
          description: 'Relative web path to the edit page of a site profile.'

    field :auth, Types::Dast::SiteProfileAuthType, null: true,
          description: 'Target authentication details.'

    field :excluded_urls, [GraphQL::Types::String], null: true,
          description: 'The URLs to skip during an authenticated scan.'

    field :request_headers, GraphQL::Types::String, null: true,
          description: 'Comma-separated list of request header names and values to be ' \
                       'added to every request made by DAST.'

    field :validation_status, Types::DastSiteProfileValidationStatusEnum, null: true,
          description: 'The current validation status of the site profile.',
          method: :status

    field :normalized_target_url, GraphQL::Types::String, null: true,
          description: 'Normalized URL of the target to be scanned.'

    field :referenced_in_security_policies, [GraphQL::Types::String], null: true,
          calls_gitaly: true,
          description: 'List of security policy names that are referencing given project.'

    def target_url
      object.dast_site.url
    end

    def edit_path
      Rails.application.routes.url_helpers.edit_project_security_configuration_dast_scans_dast_site_profile_path(object.project, object)
    end

    def auth
      object
    end

    def normalized_target_url
      DastSiteValidation.get_normalized_url_base(object.dast_site.url)
    end

    def referenced_in_security_policies
      ::Gitlab::Graphql::Aggregations::SecurityOrchestrationPolicies::LazyDastProfileAggregate.new(
        context,
        object
      )
    end
  end
end
