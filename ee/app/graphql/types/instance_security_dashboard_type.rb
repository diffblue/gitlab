# frozen_string_literal: true

module Types
  class InstanceSecurityDashboardType < BaseObject
    graphql_name 'InstanceSecurityDashboard'

    authorize :read_instance_security_dashboard

    field :projects,
          Types::ProjectType.connection_type,
          null: false,
          description: 'Projects selected in Instance Security Dashboard.',
          resolver: ::Resolvers::InstanceSecurityDashboard::ProjectsResolver

    field :vulnerability_scanners,
          ::Types::VulnerabilityScannerType.connection_type,
          null: true,
          description: 'Vulnerability scanners reported on the vulnerabilities from projects selected in Instance Security Dashboard.',
          resolver: ::Resolvers::Vulnerabilities::ScannersResolver

    field :vulnerability_severities_count, ::Types::VulnerabilitySeveritiesCountType, null: true,
                                                                                      description: 'Counts for each vulnerability severity from projects selected in Instance Security Dashboard.',
                                                                                      resolver: ::Resolvers::VulnerabilitySeveritiesCountResolver

    field :vulnerability_grades,
          [Types::VulnerableProjectsByGradeType],
          null: false,
          description: 'Represents vulnerable project counts for each grade.' do
            argument :letter_grade, Types::VulnerabilityGradeEnum,
                     required: false,
                     description: "Filter the response by given letter grade."
          end

    field :cluster_agents,
          ::Types::Clusters::AgentType.connection_type,
          extras: [:lookahead],
          null: true,
          description: 'Cluster agents associated with projects selected in the Instance Security Dashboard.',
          resolver: ::Resolvers::Clusters::AgentsResolver

    def vulnerability_grades(letter_grade: nil)
      ::Gitlab::Graphql::Aggregations::VulnerabilityStatistics::LazyAggregate.new(
        context,
        ::InstanceSecurityDashboard.new(context[:current_user]),
        filter: letter_grade
      )
    end
  end
end
