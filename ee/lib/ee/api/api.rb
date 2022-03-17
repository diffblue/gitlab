# frozen_string_literal: true

module EE
  module API
    module API
      extend ActiveSupport::Concern

      prepended do
        use ::Gitlab::Middleware::IpRestrictor

        mount ::EE::API::GroupBoards

        mount ::API::AlertManagementAlerts
        mount ::API::AuditEvents
        mount ::API::ProjectApprovalRules
        mount ::API::StatusChecks
        mount ::API::ProjectApprovalSettings
        mount ::API::Dora::Metrics
        mount ::API::EpicIssues
        mount ::API::EpicLinks
        mount ::API::Epics
        mount ::API::RelatedEpicLinks
        mount ::API::ElasticsearchIndexedNamespaces
        mount ::API::Experiments
        mount ::API::GeoReplication
        mount ::API::GeoNodes
        mount ::API::Ldap
        mount ::API::LdapGroupLinks
        mount ::API::License
        mount ::API::ProjectMirror
        mount ::API::ProjectPushRule
        mount ::API::GroupPushRule
        mount ::API::MergeTrains
        mount ::API::GroupHooks
        mount ::API::MergeRequestApprovalSettings
        mount ::API::Scim
        mount ::API::ManagedLicenses
        mount ::API::ProjectApprovals
        mount ::API::Vulnerabilities
        mount ::API::VulnerabilityFindings
        mount ::API::VulnerabilityIssueLinks
        mount ::API::VulnerabilityExports
        mount ::API::MergeRequestApprovalRules
        mount ::API::ProjectAliases
        mount ::API::Dependencies
        mount ::API::VisualReviewDiscussions
        mount ::API::Analytics::CodeReviewAnalytics
        mount ::API::Analytics::GroupActivityAnalytics
        mount ::API::Analytics::ProjectDeploymentFrequency
        mount ::API::ProtectedEnvironments
        mount ::API::ResourceWeightEvents
        mount ::API::ResourceIterationEvents
        mount ::API::Iterations
        mount ::API::GroupRepositoryStorageMoves
        mount ::API::Ci::Minutes

        mount ::API::Internal::AppSec::Dast::SiteValidations
        mount ::API::Internal::UpcomingReconciliations
      end
    end
  end
end
