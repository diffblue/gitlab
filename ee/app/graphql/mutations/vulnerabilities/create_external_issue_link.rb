# frozen_string_literal: true

module Mutations
  module Vulnerabilities
    class CreateExternalIssueLink < BaseMutation
      graphql_name 'VulnerabilityExternalIssueLinkCreate'

      authorize :admin_vulnerability

      field :external_issue_link, Types::Vulnerability::ExternalIssueLinkType,
            null: true,
            description: 'Created external issue link.'

      argument :id,
               ::Types::GlobalIDType[::Vulnerability],
               required: true,
               description: 'ID of the vulnerability.'

      argument :link_type,
               ::Types::Vulnerability::ExternalIssueLinkTypeEnum,
               required: true,
               description: 'Type of the external issue link.'

      argument :external_tracker,
               ::Types::Vulnerability::ExternalIssueLinkExternalTrackerEnum,
               required: true,
               description: 'External tracker type of the external issue link.'

      def resolve(id:, link_type:, external_tracker:)
        vulnerability = authorized_find!(id: id)
        result = create_external_issue_link(vulnerability, link_type, external_tracker)

        {
          external_issue_link: result.success? ? result.payload[:record] : nil,
          errors: result.errors
        }
      end

      private

      def create_external_issue_link(vulnerability, link_type, external_tracker)
        ::VulnerabilityExternalIssueLinks::CreateService.new(current_user, vulnerability, external_tracker, link_type: link_type).execute
      end
    end
  end
end
