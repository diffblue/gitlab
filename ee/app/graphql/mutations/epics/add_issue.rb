# frozen_string_literal: true

module Mutations
  module Epics
    class AddIssue < Base
      include Mutations::ResolvesIssuable

      graphql_name 'EpicAddIssue'

      authorize :admin_epic

      argument :project_path, GraphQL::Types::ID,
               required: true,
               description: 'The full path of the project the issue belongs to.'

      argument :issue_iid, GraphQL::Types::String,
               required: true,
               description: 'The IID of the issue to be added.'

      field :epic_issue,
            Types::EpicIssueType,
            null: true,
            description: 'The epic-issue relation.'

      def resolve(group_path:, iid:, project_path:, issue_iid:)
        epic = authorized_find!(group_path: group_path, iid: iid)
        issue = resolve_issuable(type: :issue, parent_path: project_path, iid: issue_iid)
        service = create_epic_issue(epic, issue)
        epic_issue = service[:status] == :success ? find_epic_issue(epic, issue) : nil

        {
          epic_issue: epic_issue,
          errors: service[:message] || []
        }
      end

      private

      def create_epic_issue(epic, issue)
        ::EpicIssues::CreateService.new(epic, current_user, { target_issuable: issue }).execute
      end

      def find_epic_issue(epic, issue)
        Epic.related_issues(ids: epic.id).find_by_id(issue.id)
      end
    end
  end
end
