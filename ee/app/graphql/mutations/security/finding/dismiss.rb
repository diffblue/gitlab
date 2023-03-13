# frozen_string_literal: true

module Mutations
  module Security
    module Finding
      class Dismiss < BaseMutation
        graphql_name 'SecurityFindingDismiss'

        authorize :admin_vulnerability

        field :uuid, GraphQL::Types::String,
              null: true,
              description: 'UUID of dismissed finding.'

        field :security_finding,
              ::Types::PipelineSecurityReportFindingType,
              null: true,
              description: 'Dismissed finding.'

        argument :uuid,
                GraphQL::Types::String,
                required: true,
                description: 'UUID of the finding to be dismissed.'

        argument :comment,
                GraphQL::Types::String,
                required: false,
                description: 'Comment why finding should be dismissed.'

        argument :dismissal_reason,
                Types::Vulnerabilities::DismissalReasonEnum,
                required: false,
                description: 'Reason why finding should be dismissed.'

        def resolve(uuid:, comment: nil, dismissal_reason: nil)
          security_finding = authorized_find!(uuid: uuid)
          result = dismiss_finding(security_finding, comment, dismissal_reason)

          {
            uuid: result.success? ? result.payload[:security_finding][:uuid] : nil,
            security_finding: result.success? ? result.payload[:security_finding] : nil,
            errors: Array(result.message)
          }
        end

        private

        def dismiss_finding(security_finding, comment, dismissal_reason)
          ::Security::Findings::DismissService.new(
            user: current_user,
            security_finding: security_finding,
            comment: comment,
            dismissal_reason: dismissal_reason
          ).execute
        end

        def find_object(uuid:)
          ::Security::Finding.find_by_uuid(uuid)
        end
      end
    end
  end
end
