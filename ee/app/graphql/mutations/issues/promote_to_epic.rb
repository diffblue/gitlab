# frozen_string_literal: true

module Mutations
  module Issues
    class PromoteToEpic < Base
      include Mutations::ResolvesGroup

      graphql_name 'PromoteToEpic'

      argument :group_path, GraphQL::Types::ID,
               required: false,
               description: 'The group the promoted epic will belong to.'

      field :epic,
            Types::EpicType,
            null: true,
            description: "The epic after issue promotion."

      def resolve(project_path:, iid:, group_path: nil)
        errors = []
        issue = authorized_find!(project_path: project_path, iid: iid)
        project = issue.project
        group = get_group_by_path!(group_path)

        begin
          epic = ::Epics::IssuePromoteService.new(project: project, current_user: current_user).execute(issue, group)
        rescue StandardError => error
          errors << error.message
        end

        errors << issue&.errors&.full_messages
        errors << epic&.errors&.full_messages

        {
          issue: issue,
          epic: epic,
          errors: errors.compact.flatten
        }
      end

      private

      def get_group_by_path!(group_path)
        return unless group_path

        group = resolve_group(full_path: group_path).try(:sync)
        raise raise_resource_not_available_error! unless group

        group
      end
    end
  end
end
