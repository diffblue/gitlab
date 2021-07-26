# frozen_string_literal: true

module EE
  module Types
    module ProjectType
      extend ActiveSupport::Concern

      prepended do
        field :security_scanners, ::Types::SecurityScanners, null: true,
              description: 'Information about security analyzers used in the project.',
              method: :itself

        field :vulnerabilities,
              ::Types::VulnerabilityType.connection_type,
              null: true,
              description: 'Vulnerabilities reported on the project.',
              resolver: ::Resolvers::VulnerabilitiesResolver

        field :vulnerability_scanners,
              ::Types::VulnerabilityScannerType.connection_type,
              null: true,
              description: 'Vulnerability scanners reported on the project vulnerabilities.',
              resolver: ::Resolvers::Vulnerabilities::ScannersResolver

        field :vulnerabilities_count_by_day,
              ::Types::VulnerabilitiesCountByDayType.connection_type,
              null: true,
              description: 'Number of vulnerabilities per day for the project.',
              resolver: ::Resolvers::VulnerabilitiesCountPerDayResolver

        field :vulnerability_severities_count, ::Types::VulnerabilitySeveritiesCountType, null: true,
              description: 'Counts for each vulnerability severity in the project.',
              resolver: ::Resolvers::VulnerabilitySeveritiesCountResolver

        field :requirement, ::Types::RequirementsManagement::RequirementType, null: true,
              description: 'Find a single requirement.',
              resolver: ::Resolvers::RequirementsManagement::RequirementsResolver.single

        field :requirements, ::Types::RequirementsManagement::RequirementType.connection_type, null: true,
              description: 'Find requirements.',
              extras: [:lookahead],
              resolver: ::Resolvers::RequirementsManagement::RequirementsResolver

        field :requirement_states_count, ::Types::RequirementsManagement::RequirementStatesCountType, null: true,
              description: 'Number of requirements for the project by their state.'

        field :compliance_frameworks, ::Types::ComplianceManagement::ComplianceFrameworkType.connection_type,
              description: 'Compliance frameworks associated with the project.',
              null: true

        field :security_dashboard_path, GraphQL::Types::String,
              description: "Path to project's security dashboard.",
              null: true

        field :iterations, ::Types::IterationType.connection_type, null: true,
              description: 'Find iterations.',
              resolver: ::Resolvers::IterationsResolver

        field :iteration_cadences, ::Types::Iterations::CadenceType.connection_type, null: true,
              description: 'Find iteration cadences.',
              resolver: ::Resolvers::Iterations::CadencesResolver

        field :dast_profiles,
              ::Types::Dast::ProfileType.connection_type,
              null: true,
              resolver: ::Resolvers::AppSec::Dast::ProfileResolver,
              description: 'DAST Profiles associated with the project.'

        field :dast_site_profile,
              ::Types::DastSiteProfileType,
              null: true,
              resolver: ::Resolvers::DastSiteProfileResolver.single,
              description: 'DAST Site Profile associated with the project.'

        field :dast_site_profiles,
              ::Types::DastSiteProfileType.connection_type,
              null: true,
              description: 'DAST Site Profiles associated with the project.',
              resolver: ::Resolvers::DastSiteProfileResolver

        field :dast_scanner_profiles,
              ::Types::DastScannerProfileType.connection_type,
              null: true,
              description: 'The DAST scanner profiles associated with the project.'

        field :dast_site_validations,
              ::Types::DastSiteValidationType.connection_type,
              null: true,
              resolver: ::Resolvers::DastSiteValidationResolver,
              description: 'DAST Site Validations associated with the project.'

        field :agent_configurations,
              ::Types::Kas::AgentConfigurationType.connection_type,
              null: true,
              description: 'Agent configurations defined by the project',
              resolver: ::Resolvers::Kas::AgentConfigurationsResolver

        field :cluster_agent,
              ::Types::Clusters::AgentType,
              null: true,
              description: 'Find a single cluster agent by name.',
              resolver: ::Resolvers::Clusters::AgentsResolver.single

        field :cluster_agents,
              ::Types::Clusters::AgentType.connection_type,
              extras: [:lookahead],
              null: true,
              description: 'Cluster agents associated with the project.',
              resolver: ::Resolvers::Clusters::AgentsResolver

        field :repository_size_excess,
              GraphQL::FLOAT_TYPE,
              null: true,
              description: 'Size of repository that exceeds the limit in bytes.'

        field :actual_repository_size_limit,
              GraphQL::FLOAT_TYPE,
              null: true,
              description: 'Size limit for the repository in bytes.',
              method: :actual_size_limit

        field :code_coverage_summary,
              ::Types::Ci::CodeCoverageSummaryType,
              null: true,
              description: 'Code coverage summary associated with the project.',
              resolver: ::Resolvers::Ci::CodeCoverageSummaryResolver

        field :alert_management_payload_fields,
              [::Types::AlertManagement::PayloadAlertFieldType],
              null: true,
              description: 'Extract alert fields from payload for custom mapping.',
              resolver: ::Resolvers::AlertManagement::PayloadAlertFieldResolver

        field :incident_management_oncall_schedules,
              ::Types::IncidentManagement::OncallScheduleType.connection_type,
              null: true,
              description: 'Incident Management On-call schedules of the project.',
              extras: [:lookahead],
              resolver: ::Resolvers::IncidentManagement::OncallScheduleResolver

        field :incident_management_escalation_policies,
              ::Types::IncidentManagement::EscalationPolicyType.connection_type,
              null: true,
              description: 'Incident Management escalation policies of the project.',
              extras: [:lookahead],
              resolver: ::Resolvers::IncidentManagement::EscalationPoliciesResolver

        field :incident_management_escalation_policy,
              ::Types::IncidentManagement::EscalationPolicyType,
              null: true,
              description: 'Incident Management escalation policy of the project.',
              resolver: ::Resolvers::IncidentManagement::EscalationPoliciesResolver.single

        field :api_fuzzing_ci_configuration,
              ::Types::AppSec::Fuzzing::API::CiConfigurationType,
              null: true,
              description: 'API fuzzing configuration for the project. '

        field :push_rules,
              ::Types::PushRulesType,
              null: true,
              description: "The project's push rules settings.",
              method: :push_rule

        field :path_locks,
              ::Types::PathLockType.connection_type,
              null: true,
              description: "The project's path locks.",
              extras: [:lookahead],
              resolver: ::Resolvers::PathLocksResolver

        field :scan_execution_policies,
              ::Types::ScanExecutionPolicyType.connection_type,
              calls_gitaly: true,
              null: true,
              description: 'Scan Execution Policies of the project',
              resolver: ::Resolvers::ScanExecutionPolicyResolver

        field :network_policies,
              ::Types::NetworkPolicyType.connection_type,
              null: true,
              description: 'Network Policies of the project',
              resolver: ::Resolvers::NetworkPolicyResolver

        field :dora,
              ::Types::DoraType,
              null: true,
              method: :itself,
              description: "The project's DORA metrics."
      end

      def api_fuzzing_ci_configuration
        return unless Ability.allowed?(current_user, :read_security_resource, object)

        configuration = ::AppSec::Fuzzing::API::CiConfiguration.new(project: object)

        {
          scan_modes: ::AppSec::Fuzzing::API::CiConfiguration::SCAN_MODES,
          scan_profiles: configuration.scan_profiles
        }
      end

      def dast_scanner_profiles
        DastScannerProfilesFinder.new(project_ids: [object.id]).execute
      end

      def requirement_states_count
        return unless Ability.allowed?(current_user, :read_requirement, object)

        Hash.new(0).merge(object.requirements.counts_by_state)
      end

      def security_dashboard_path
        Rails.application.routes.url_helpers.project_security_dashboard_index_path(object)
      end

      def compliance_frameworks
        BatchLoader::GraphQL.for(object.id).batch(default_value: []) do |project_ids, loader|
          results = ::ComplianceManagement::Framework.with_projects(project_ids)

          results.each do |framework|
            framework.project_ids.each do |project_id|
              loader.call(project_id) { |xs| xs << framework }
            end
          end
        end
      end
    end
  end
end
