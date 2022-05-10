# frozen_string_literal: true

module Mutations
  module Vulnerabilities
    class DestroyExternalIssueLink < BaseMutation
      graphql_name 'VulnerabilityExternalIssueLinkDestroy'

      authorize :admin_vulnerability_external_issue_link

      ERROR_MSG = 'Error deleting the vulnerability external issue link'

      argument :id, ::Types::GlobalIDType[::Vulnerabilities::ExternalIssueLink],
               required: true,
               description: 'Global ID of the vulnerability external issue link.'

      def resolve(id:)
        vulnerability_external_issue_link = authorized_find!(id: id)

        response = ::VulnerabilityExternalIssueLinks::DestroyService.new(vulnerability_external_issue_link).execute
        errors = response.destroyed? ? [] : [ERROR_MSG]

        {
          errors: errors
        }
      end

      private

      def find_object(id:)
        GitlabSchema.find_by_gid(id)
      end
    end
  end
end
