# frozen_string_literal: true

module Mutations
  module Security
    module Finding
      class CreateIssue < BaseMutation
        graphql_name 'SecurityFindingCreateIssue'

        authorize :admin_vulnerability

        field :issue, Types::IssueType,
              null: true,
              description: 'Issue created after mutation.'

        argument :uuid,
                GraphQL::Types::String,
                required: true,
                description: 'UUID of the security finding to be used to create an issue.'

        argument :project, ::Types::GlobalIDType[::Project],
                required: true,
                description: 'ID of the project to attach the issue to.'

        def resolve(uuid:, project:)
          project = authorized_find!(id: project)
          unless ::Feature.enabled?(:deprecate_vulnerabilities_feedback, project)
            return { errors: ['Feature flag disabled'] }
          end

          params = { security_finding_uuid: uuid }
          issue_response = ::Vulnerabilities::SecurityFinding::CreateIssueService.new(project: project,
                                                                                      current_user: current_user,
                                                                                      params: params).execute

          return { errors: [issue_response[:message]] } if issue_response.error?

          { errors: [], issue: issue_response[:issue] }
        end
      end
    end
  end
end
