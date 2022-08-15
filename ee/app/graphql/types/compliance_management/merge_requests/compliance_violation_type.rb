# frozen_string_literal: true

module Types
  module ComplianceManagement
    module MergeRequests
      class ComplianceViolationType < ::Types::BaseObject
        graphql_name 'ComplianceViolation'
        description 'Compliance violation associated with a merged merge request.'

        authorize :read_group_compliance_dashboard

        field :id, GraphQL::Types::ID,
          null: false, description: 'Compliance violation ID.'

        field :severity_level, ComplianceViolationSeverityEnum,
          null: false, description: 'Severity of the compliance violation.'

        field :reason, ComplianceViolationReasonEnum,
          null: false, description: 'Reason the compliance violation occurred.'

        field :violating_user, ::Types::UserType,
          null: false, description: 'User suspected of causing the compliance violation.'

        field :merge_request, ::Types::MergeRequestType,
          null: false, description: 'Merge request the compliance violation occurred in.'
      end
    end
  end
end
