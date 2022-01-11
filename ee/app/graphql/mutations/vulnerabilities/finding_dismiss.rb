# frozen_string_literal: true

module Mutations
  module Vulnerabilities
    class FindingDismiss < BaseMutation
      graphql_name 'VulnerabilityFindingDismiss'

      authorize :admin_vulnerability

      field :finding, Types::PipelineSecurityReportFindingType,
            null: true,
            description: 'Finding after dismissal.'

      argument :id,
               ::Types::GlobalIDType[::Vulnerabilities::Finding],
               required: true,
               description: 'ID of the finding to be dismissed.'

      argument :comment,
               GraphQL::Types::String,
               required: false,
               description: 'Comment why finding should be dismissed.'

      argument :dismissal_reason,
               Types::Vulnerabilities::DismissalReasonEnum,
               required: false,
               description: 'Reason why finding should be dismissed.'

      def resolve(id:, comment: nil, dismissal_reason: nil)
        finding = authorized_find!(id: id)
        result = dismiss_finding(finding, comment, dismissal_reason)

        {
          finding: result.success? ? result.payload[:finding] : nil,
          errors: result.message || []
        }
      end

      private

      def dismiss_finding(finding, comment, dismissal_reason)
        ::Vulnerabilities::FindingDismissService.new(
          current_user,
          finding,
          comment,
          dismissal_reason
        ).execute
      end

      def find_object(id:)
        id = ::Types::GlobalIDType[::Vulnerabilities::Finding].coerce_isolated_input(id)
        GitlabSchema.find_by_gid(id)
      end
    end
  end
end
