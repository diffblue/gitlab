# frozen_string_literal: true

module Mutations
  module Issues
    class SetEpic < Base
      graphql_name 'IssueSetEpic'

      argument :epic_id,
               ::Types::GlobalIDType[::Epic],
               required: false,
               loads: Types::EpicType,
               description: 'Global ID of the epic to be assigned to the issue, ' \
               'epic will be removed if absent or set to null'

      def resolve(project_path:, iid:, epic: nil)
        issue = authorized_find!(project_path: project_path, iid: iid)
        project = issue.project

        authorize_admin_rights!(issue)

        begin
          ::Issues::UpdateService.new(project: project, current_user: current_user, params: { epic: epic })
            .execute(issue)
        rescue EE::Issues::BaseService::EpicAssignmentError => error
          issue.errors.add(:base, error.message)
        end

        {
          issue: issue,
          errors: issue.errors.full_messages
        }
      end

      private

      def authorize_admin_rights!(issue)
        return unless issue.present?

        raise_resource_not_available_error! unless Ability.allowed?(current_user, :admin_issue, issue)
      end
    end
  end
end
