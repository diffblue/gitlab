# frozen_string_literal: true

module EE
  module Types
    module ProjectType
      extend ActiveSupport::Concern

      prepended do
        field :security_scanners, ::Types::SecurityScanners,
              null: true,
              description: 'Information about security analyzers used in the project.',
              method: :itself

        field :security_training_providers, [::Types::Security::TrainingType],
              null: true,
              description: 'List of security training providers for the project',
              resolver: ::Resolvers::SecurityTrainingProvidersResolver

        field :vulnerabilities, ::Types::VulnerabilityType.connection_type,
              null: true,
              extras: [:lookahead],
              description: 'Vulnerabilities reported on the project.',
              resolver: ::Resolvers::VulnerabilitiesResolver

        field :vulnerability_scanners, ::Types::VulnerabilityScannerType.connection_type,
              null: true,
              description: 'Vulnerability scanners reported on the project vulnerabilities.',
              resolver: ::Resolvers::Vulnerabilities::ScannersResolver

        field :vulnerabilities_count_by_day, ::Types::VulnerabilitiesCountByDayType.connection_type,
              null: true,
              description: 'The historical number of vulnerabilities per day for the project.',
              resolver: ::Resolvers::VulnerabilitiesCountPerDayResolver

        field :vulnerability_severities_count, ::Types::VulnerabilitySeveritiesCountType,
              null: true,
              description: 'Counts for each vulnerability severity in the project.',
              resolver: ::Resolvers::VulnerabilitySeveritiesCountResolver

        field :requirement, ::Types::RequirementsManagement::RequirementType,
              null: true,
              description: 'Find a single requirement.',
              resolver: ::Resolvers::RequirementsManagement::RequirementsResolver.single

        field :requirements, ::Types::RequirementsManagement::RequirementType.connection_type,
              null: true,
              description: 'Find requirements.',
              extras: [:lookahead],
              resolver: ::Resolvers::RequirementsManagement::RequirementsResolver

        field :requirement_states_count, ::Types::RequirementsManagement::RequirementStatesCountType,
              null: true,
              description: 'Number of requirements for the project by their state.'

        field :compliance_frameworks, ::Types::ComplianceManagement::ComplianceFrameworkType.connection_type,
              description: 'Compliance frameworks associated with the project.',
              null: true

        field :security_dashboard_path, GraphQL::Types::String,
              description: "Path to project's security dashboard.",
              null: true

        field :iterations, ::Types::IterationType.connection_type,
              null: true,
              description: 'Find iterations.',
              resolver: ::Resolvers::IterationsResolver

        field :iteration_cadences, ::Types::Iterations::CadenceType.connection_type,
              null: true,
              description: 'Find iteration cadences.',
              resolver: ::Resolvers::Iterations::CadencesResolver

        field :dast_profile,
              ::Types::Dast::ProfileType,
              null: true,
              resolver: ::Resolvers::AppSec::Dast::ProfileResolver.single,
              description: 'DAST Profile associated with the project.'

        field :dast_profiles,
              ::Types::Dast::ProfileType.connection_type,
              null: true,
              extras: [:lookahead],
              late_extensions: [::Gitlab::Graphql::Project::DastProfileConnectionExtension],
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
              description: 'DAST scanner profiles associated with the project.'

        field :dast_site_validations,
              ::Types::DastSiteValidationType.connection_type,
              null: true,
              resolver: ::Resolvers::DastSiteValidationResolver,
              description: 'DAST Site Validations associated with the project.'

        field :repository_size_excess,
              GraphQL::Types::Float,
              null: true,
              description: 'Size of repository that exceeds the limit in bytes.'

        field :actual_repository_size_limit,
              GraphQL::Types::Float,
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

        field :corpuses, ::Types::AppSec::Fuzzing::Coverage::CorpusType.connection_type,
              null: true,
              resolver: ::Resolvers::AppSec::Fuzzing::Coverage::CorpusesResolver,
              description: "Find corpuses of the project."

        field :push_rules,
              ::Types::PushRulesType,
              null: true,
              description: "Project's push rules settings.",
              method: :push_rule

        field :path_locks,
              ::Types::PathLockType.connection_type,
              null: true,
              description: "The project's path locks.",
              extras: [:lookahead],
              resolver: ::Resolvers::PathLocksResolver

        field :scan_execution_policies,
              ::Types::SecurityOrchestration::ScanExecutionPolicyType.connection_type,
              calls_gitaly: true,
              null: true,
              description: 'Scan Execution Policies of the project',
              resolver: ::Resolvers::SecurityOrchestration::ScanExecutionPolicyResolver

        field :scan_result_policies,
              ::Types::SecurityOrchestration::ScanResultPolicyType.connection_type,
              calls_gitaly: true,
              null: true,
              description: 'Scan Result Policies of the project',
              resolver: ::Resolvers::SecurityOrchestration::ScanResultPolicyResolver

        field :network_policies,
              ::Types::NetworkPolicyType.connection_type,
              null: true,
              deprecated: {
                reason: 'Network policies are deprecated and will be removed in GitLab 16.0. Since GitLab 15.0 ' \
                        'this field returns no data',
                milestone: '14.8'
              },
              description: 'Network Policies of the project',
              resolver: ::Resolvers::NetworkPolicyResolver

        field :dora,
              ::Types::DoraType,
              null: true,
              method: :itself,
              description: "Project's DORA metrics."

        field :security_training_urls,
              [::Types::Security::TrainingUrlType],
              null: true,
              description: 'Security training URLs for the enabled training providers of the project.',
              resolver: ::Resolvers::SecurityTrainingUrlsResolver

        field :vulnerability_images,
              type: ::Types::Vulnerabilities::ContainerImageType.connection_type,
              null: true,
              description: 'Container images reported on the project vulnerabilities.',
              resolver: ::Resolvers::Vulnerabilities::ContainerImagesResolver

        field :only_allow_merge_if_all_status_checks_passed, GraphQL::Types::Boolean,
              null: true,
              description: 'Indicates that merges of merge requests should be blocked ' \
                           'unless all status checks have passed.'

        field :gitlab_subscriptions_preview_billable_user_change,
              ::Types::GitlabSubscriptions::PreviewBillableUserChangeType,
              null: true,
              complexity: 100,
              description: 'Preview Billable User Changes',
              resolver: ::Resolvers::GitlabSubscriptions::PreviewBillableUserChangeResolver

        field :product_analytics_dashboards, ::Types::ProductAnalytics::DashboardType.connection_type,
              description: 'Product Analytics dashboards of the project.',
              null: true,
              calls_gitaly: true,
              alpha: { milestone: '15.6' },
              resolver: ::Resolvers::ProductAnalytics::DashboardsResolver

        field :product_analytics_state, ::Types::ProductAnalytics::StateEnum,
              description: 'Current state of the product analytics stack for this project.' \
                           'Can only be called for one project in a single request',
              null: true,
              alpha: { milestone: '15.10' },
              resolver: ::Resolvers::ProductAnalytics::StateResolver do
                extension ::Gitlab::Graphql::Limit::FieldCallCount, limit: 1
              end

        field :tracking_key, GraphQL::Types::String,
              null: true,
              description: 'Tracking key assigned to the project.',
              alpha: { milestone: '16.0' },
              authorize: :developer_access

        field :product_analytics_instrumentation_key, GraphQL::Types::String,
              null: true,
              description: 'Product Analytics instrumentation key assigned to the project.',
              alpha: { milestone: '16.0' },
              authorize: :developer_access

        field :ai_conversations,
              ::Types::Ai::ProjectConversationsType,
              resolver: ::Resolvers::Ai::ProjectConversationsResolver,
              null: true,
              description: "Ai Chat conversations related to a given project.",
              alpha: { milestone: '16.0' }

        field :dependencies, ::Types::Sbom::DependencyType.connection_type,
              null: true,
              description: 'Software dependencies used by the project.',
              alpha: { milestone: '15.9' },
              resolver: ::Resolvers::Sbom::DependenciesResolver
        field :merge_requests_disable_committers_approval, GraphQL::Types::Boolean,
          null: false,
          description: 'Indicates that committers of the given merge request cannot approve.'
      end

      def tracking_key
        return unless object.product_analytics_enabled?
        return object.project_setting.jitsu_key unless ::Feature.enabled?(:product_analytics_snowplow_support)

        object.project_setting.product_analytics_instrumentation_key || object.project_setting.jitsu_key
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
