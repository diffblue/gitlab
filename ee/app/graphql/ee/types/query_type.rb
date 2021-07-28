# frozen_string_literal: true

module EE
  module Types
    module QueryType
      extend ActiveSupport::Concern

      prepended do
        field :iteration, ::Types::IterationType,
              null: true,
              description: 'Find an iteration.' do
          argument :id, ::Types::GlobalIDType[::Iteration],
                   required: true,
                   description: 'Find an iteration by its ID.'
        end

        field :vulnerabilities,
              ::Types::VulnerabilityType.connection_type,
              null: true,
              description: "Vulnerabilities reported on projects on the current user's instance security dashboard.",
              resolver: ::Resolvers::VulnerabilitiesResolver

        field :vulnerability,
              ::Types::VulnerabilityType,
              null: true,
              description: "Find a vulnerability." do
          argument :id, ::Types::GlobalIDType[::Vulnerability],
                   required: true,
                   description: 'The Global ID of the Vulnerability.'
        end

        field :vulnerabilities_count_by_day,
              ::Types::VulnerabilitiesCountByDayType.connection_type,
              null: true,
              resolver: ::Resolvers::VulnerabilitiesCountPerDayResolver,
              description: <<~DESC
                Number of vulnerabilities per day for the projects on the current user's instance security dashboard.
              DESC

        field :geo_node, ::Types::Geo::GeoNodeType,
              null: true,
              resolver: ::Resolvers::Geo::GeoNodeResolver,
              description: 'Find a Geo node.'

        field :instance_security_dashboard, ::Types::InstanceSecurityDashboardType,
              null: true,
              resolver: ::Resolvers::InstanceSecurityDashboardResolver,
              description: 'Fields related to Instance Security Dashboard.'

        field :devops_adoption_enabled_namespaces, ::Types::Analytics::DevopsAdoption::EnabledNamespaceType.connection_type,
              null: true,
              description: 'Get configured DevOps adoption namespaces. **BETA** This endpoint is subject to change without notice.',
              resolver: ::Resolvers::Analytics::DevopsAdoption::EnabledNamespacesResolver

        field :current_license, ::Types::Admin::CloudLicenses::CurrentLicenseType,
              null: true,
              resolver: ::Resolvers::Admin::CloudLicenses::CurrentLicenseResolver,
              description: 'Fields related to the current license.'

        field :license_history_entries, ::Types::Admin::CloudLicenses::LicenseHistoryEntryType.connection_type,
              null: true,
              resolver: ::Resolvers::Admin::CloudLicenses::LicenseHistoryEntriesResolver,
              description: 'Fields related to entries in the license history.'

        field :ci_minutes_usage, ::Types::Ci::Minutes::NamespaceMonthlyUsageType.connection_type,
              null: true,
              description: 'The monthly CI minutes usage data for the current user.'
      end

      def vulnerability(id:)
        # TODO: remove this line when the compatibility layer is removed
        # See: https://gitlab.com/gitlab-org/gitlab/-/issues/257883
        id = ::Types::GlobalIDType[::Vulnerability].coerce_isolated_input(id)
        ::GitlabSchema.find_by_gid(id)
      end

      def iteration(id:)
        # TODO: remove this line when the compatibility layer is removed
        # See: https://gitlab.com/gitlab-org/gitlab/-/issues/257883
        id = ::Types::GlobalIDType[Iteration].coerce_isolated_input(id)
        ::GitlabSchema.find_by_gid(id)
      end

      def ci_minutes_usage
        ::Ci::Minutes::NamespaceMonthlyUsage.for_namespace(current_user.namespace)
      end
    end
  end
end
