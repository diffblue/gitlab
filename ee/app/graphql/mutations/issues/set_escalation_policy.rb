# frozen_string_literal: true

module Mutations
  module Issues
    class SetEscalationPolicy < Base
      graphql_name 'IssueSetEscalationPolicy'

      argument :escalation_policy_id,
               ::Types::GlobalIDType[::IncidentManagement::EscalationPolicy],
               required: false,
               loads: Types::IncidentManagement::EscalationPolicyType,
               description: 'Global ID of the escalation policy to assign to the issue. ' \
               'Policy will be removed if absent or set to null.'

      def resolve(project_path:, iid:, escalation_policy:)
        issue = authorized_find!(project_path: project_path, iid: iid)
        project = issue.project

        authorize_escalation_status!(project)

        ::Issues::UpdateService.new(
          project: project,
          current_user: current_user,
          params: { escalation_status: { policy: escalation_policy } }
        ).execute(issue)

        {
          issue: issue,
          errors: errors_on_object(issue)
        }
      end

      private

      def authorize_escalation_status!(project)
        return if Ability.allowed?(current_user, :update_escalation_status, project)

        raise_resource_not_available_error!
      end
    end
  end
end
