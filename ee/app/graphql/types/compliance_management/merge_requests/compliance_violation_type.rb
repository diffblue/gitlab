# frozen_string_literal: true

module Types
  module ComplianceManagement
    module MergeRequests
      class ComplianceViolationType < ::Types::BaseObject
        graphql_name 'ComplianceViolation'
        description 'Compliance violation associated with a merged merge request.' \
                    ' Available only when feature flag `compliance_violations_graphql_type` is enabled. This flag is disabled by default, because the feature is experimental and is subject to change without notice.'

        authorize :read_group_compliance_dashboard

        field :id, GraphQL::Types::ID, null: false,
              description: 'Compliance violation ID.'

        field :severity_level, ComplianceViolationSeverityEnum, null: false,
              description: 'Severity of the compliance violation.'

        field :reason, ComplianceViolationReasonEnum, null: false,
              description: 'Reason the compliance violation occurred.'

        field :violating_user, ::Types::UserType, null: false,
              description: 'User suspected of causing the compliance violation.'

        field :merge_request, ::Types::MergeRequestType, null: false,
              description: 'Merge request the compliance violation occurred in.'
      end
    end
  end
end
