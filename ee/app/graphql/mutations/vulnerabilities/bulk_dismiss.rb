# frozen_string_literal: true

module Mutations
  module Vulnerabilities
    class BulkDismiss < BaseMutation
      graphql_name 'VulnerabilitiesDismiss'
      authorize :admin_vulnerability

      argument :vulnerability_ids,
        [::Types::GlobalIDType[::Vulnerability]],
        required: true,
        prepare: ->(vulnerability_ids, ctx) {
          ::Mutations::Vulnerabilities::BulkDismiss.prepare(vulnerability_ids, ctx)
        },
        description: "IDs of the vulnerabilities to be dismissed."

      argument :comment,
        GraphQL::Types::String,
        required: false,
        description: "Comment why vulnerability was dismissed (maximum 50,000 characters)."

      argument :dismissal_reason,
        Types::Vulnerabilities::DismissalReasonEnum,
        required: false,
        description: 'Reason why vulnerability should be dismissed.'

      field :vulnerabilities, [Types::VulnerabilityType],
        null: false,
        description: 'Vulnerabilities after state change.'

      def resolve(comment: nil, dismissal_reason: nil, vulnerability_ids: [])
        ids = vulnerability_ids.map(&:model_id).uniq

        response = ::Vulnerabilities::BulkDismissService.new(
          current_user,
          ids,
          comment,
          dismissal_reason
        ).execute

        {
          vulnerabilities: response[:vulnerabilities] || [],
          errors: response.success? ? [] : [response.message]
        }
      rescue Gitlab::Access::AccessDeniedError
        raise_resource_not_available_error!
      end

      def self.prepare(vulnerability_ids, _ctx)
        max_vulnerabilities = ::Vulnerabilities::BulkDismissService::MAX_BATCH
        if vulnerability_ids.length > max_vulnerabilities
          raise GraphQL::ExecutionError, "Maximum vulnerability_ids exceeded (#{max_vulnerabilities})"
        elsif vulnerability_ids.empty?
          raise GraphQL::ExecutionError, "At least 1 value must be provided for vulnerability_ids"
        end

        vulnerability_ids
      end
    end
  end
end
