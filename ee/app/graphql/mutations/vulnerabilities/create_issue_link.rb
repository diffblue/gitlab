# frozen_string_literal: true

module Mutations
  module Vulnerabilities
    class CreateIssueLink < BaseMutation
      graphql_name 'VulnerabilityIssueLinkCreate'

      MAX_VULNERABILITIES = 100

      # This authorization is used for the **Issue only**.  The vulnerabilities
      # access is checked against :admin_vulnerability_issue_link
      authorize :read_issue

      field :issue_links,
        [Types::Vulnerability::IssueLinkType],
        null: true,
        description: 'Created issue links.'

      argument :issue_id,
        ::Types::GlobalIDType[::Issue],
        required: true,
        description: 'ID of the issue to link to.'

      argument :vulnerability_ids,
        [::Types::GlobalIDType[::Vulnerability]],
        required: true,
        prepare: ->(vulnerability_ids, _ctx) {
          if vulnerability_ids.length > MAX_VULNERABILITIES
            raise GraphQL::ExecutionError, "Maximum vulnerability_ids exceeded (#{MAX_VULNERABILITIES})"
          elsif vulnerability_ids.empty?
            raise GraphQL::ExecutionError, "At least 1 value must be provided for vulnerability_ids"
          end

          vulnerability_ids
        },
        description: "IDs of vulnerabilities to link to the given issue.  Up to #{MAX_VULNERABILITIES} can be provided."

      def resolve(issue_id:, vulnerability_ids:)
        issue = authorized_find!(id: issue_id)
        result = create_issue_links(issue, vulnerabilities(vulnerability_ids))
        {
          issue_links: result.success? ? result.payload[:issue_links].with_associations : nil,
          errors: result.errors
        }
      end

      private

      def vulnerabilities(vulnerability_ids)
        vulnerabilities = Vulnerability.id_in(vulnerability_ids.map(&:model_id)).with_projects

        raise_resource_not_available_error! unless vulnerabilities.all? do |vulnerability|
          Ability.allowed?(current_user, :admin_vulnerability_issue_link, vulnerability)
        end

        vulnerabilities
      end

      def find_object(id:)
        GitlabSchema.find_by_gid(id)
      end

      def create_issue_links(issue, vulnerabilities)
        ::VulnerabilityIssueLinks::BulkCreateService.new(current_user, issue, vulnerabilities).execute
      end
    end
  end
end
