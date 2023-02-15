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

        authorize_read_rights!(epic)

        begin
          ::Issues::UpdateService.new(container: project, current_user: current_user, params: { epic: epic })
            .execute(issue)
        rescue ::Gitlab::Access::AccessDeniedError
          raise_resource_not_available_error!
        rescue EE::Issues::BaseService::EpicAssignmentError => error
          issue.errors.add(:base, error.message)
        end

        {
          issue: issue,
          errors: issue.errors.full_messages
        }
      end

      private

      def authorize_read_rights!(epic)
        return unless epic.present?

        raise_resource_not_available_error! unless Ability.allowed?(current_user, :read_epic, epic.group)
      end
    end
  end
end
