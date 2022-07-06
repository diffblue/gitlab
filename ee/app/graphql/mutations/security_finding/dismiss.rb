# frozen_string_literal: true

module Mutations
  module SecurityFinding
    class Dismiss < BaseMutation
      graphql_name 'VulnerabilityFindingDismiss'

      authorize :admin_vulnerability

      field :finding, Types::PipelineSecurityReportFindingType,
            null: true,
            description: 'Finding after dismissal.'

      argument :id,
               ::Types::GlobalIDType[::Vulnerabilities::Finding],
               required: false,
               deprecated: { reason: 'Use `uuid`', milestone: '15.2' },
               description: 'ID of the finding to be dismissed.'

      argument :uuid,
               GraphQL::Types::String,
               required: false,
               description: 'UUID of the finding to be dismissed.'

      argument :comment,
               GraphQL::Types::String,
               required: false,
               description: 'Comment why finding should be dismissed.'

      argument :dismissal_reason,
               Types::Vulnerabilities::DismissalReasonEnum,
               required: false,
               description: 'Reason why finding should be dismissed.'

      def resolve(id: nil, uuid: nil, comment: nil, dismissal_reason: nil)
        unless id || uuid
          raise ::Gitlab::Graphql::Errors::ArgumentError, "Must provide either uuid (preferred) or id argument"
        end

        finding = authorized_find!(id: id, uuid: uuid)
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

      def find_object(id:, uuid:)
        uuid ? ::Vulnerabilities::Finding.find_by_uuid(uuid) : GitlabSchema.find_by_gid(id)
      end
    end
  end
end
