# frozen_string_literal: true

module EE
  module Types
    module GroupType
      extend ActiveSupport::Concern

      prepended do
        %i[epics].each do |feature|
          field "#{feature}_enabled", GraphQL::Types::Boolean, null: true,
                description: "Indicates if #{feature.to_s.humanize} are enabled for namespace"

          define_method "#{feature}_enabled" do
            object.feature_available?(feature)
          end
        end

        field :epic, ::Types::EpicType, null: true,
              description: 'Find a single epic.',
              resolver: ::Resolvers::EpicsResolver.single

        field :epics, ::Types::EpicType.connection_type, null: true,
              description: 'Find epics.',
              extras: [:lookahead],
              resolver: ::Resolvers::EpicsResolver

        field :epic_board,
              ::Types::Boards::EpicBoardType, null: true,
              description: 'Find a single epic board.',
              resolver: ::Resolvers::Boards::EpicBoardsResolver.single

        field :epic_boards,
              ::Types::Boards::EpicBoardType.connection_type, null: true,
              description: 'Find epic boards.',
              resolver: ::Resolvers::Boards::EpicBoardsResolver

        field :iterations, ::Types::IterationType.connection_type, null: true,
              description: 'Find iterations.',
              resolver: ::Resolvers::IterationsResolver

        field :iteration_cadences, ::Types::Iterations::CadenceType.connection_type, null: true,
              description: 'Find iteration cadences.',
              resolver: ::Resolvers::Iterations::CadencesResolver

        field :vulnerabilities,
              ::Types::VulnerabilityType.connection_type,
              null: true,
              extras: [:lookahead],
              description: 'Vulnerabilities reported on the projects in the group and its subgroups.',
              resolver: ::Resolvers::VulnerabilitiesResolver

        field :vulnerability_scanners,
              ::Types::VulnerabilityScannerType.connection_type,
              null: true,
              description: 'Vulnerability scanners reported on the project vulnerabilities of the group and its subgroups.',
              resolver: ::Resolvers::Vulnerabilities::ScannersResolver

        field :vulnerability_severities_count, ::Types::VulnerabilitySeveritiesCountType, null: true,
              description: 'Counts for each vulnerability severity in the group and its subgroups.',
              resolver: ::Resolvers::VulnerabilitySeveritiesCountResolver

        field :vulnerabilities_count_by_day,
              ::Types::VulnerabilitiesCountByDayType.connection_type,
              null: true,
              description: 'The historical number of vulnerabilities per day for the projects in the group and its subgroups.',
              resolver: ::Resolvers::VulnerabilitiesCountPerDayResolver

        field :vulnerability_grades,
              [::Types::VulnerableProjectsByGradeType],
              null: false,
              description: 'Represents vulnerable project counts for each grade.',
              resolver: ::Resolvers::VulnerabilitiesGradeResolver

        field :code_coverage_activities,
              ::Types::Ci::CodeCoverageActivityType.connection_type,
              null: true,
              description: 'Represents the code coverage activity for this group.',
              resolver: ::Resolvers::Ci::CodeCoverageActivitiesResolver

        field :stats,
              ::Types::GroupStatsType,
              null: true,
              description: 'Group statistics.',
              method: :itself

        field :billable_members_count, ::GraphQL::Types::Int,
              null: true,
              description: 'Number of billable users in the group.'

        field :dora,
              ::Types::DoraType,
              null: true,
              method: :itself,
              description: "Group's DORA metrics."

        field :external_audit_event_destinations,
              ::Types::AuditEvents::ExternalAuditEventDestinationType.connection_type,
              null: true,
              description: 'External locations that receive audit events belonging to the group.',
              authorize: :admin_external_audit_events

        field :merge_request_violations,
              ::Types::ComplianceManagement::MergeRequests::ComplianceViolationType.connection_type,
              null: true,
              description: 'Compliance violations reported on merge requests merged within the group.' \
                           ' Available only when feature flag `compliance_violations_graphql_type` is enabled. This flag is disabled by default, because the feature is experimental and is subject to change without notice.',
              resolver: ::Resolvers::ComplianceManagement::MergeRequests::ComplianceViolationResolver
      end
    end
  end
end
