# frozen_string_literal: true

module EE
  module Issues
    module UpdateService
      extend ::Gitlab::Utils::Override
      include ::Gitlab::Utils::StrongMemoize

      override :filter_params
      def filter_params(issue)
        params.delete(:sprint_id) unless can_admin_issuable?(issue)

        filter_epic(issue)
        filter_iteration

        super
      end

      override :execute
      def execute(issue)
        handle_promotion(issue)

        result = super

        if issue.previous_changes.include?(:milestone_id) && issue.epic
          Epics::UpdateDatesService.new([issue.epic]).execute
        end

        ::Gitlab::StatusPage.trigger_publish(project, current_user, issue) if issue.valid?

        result
      end

      override :handle_changes
      def handle_changes(issue, _options)
        super

        handle_iteration_change(issue)
        handle_weight_change(issue)
      end

      override :before_update
      def before_update(issue, **args)
        super

        assign_requirement_to_be_synced_for(issue)
      end

      override :after_update
      def after_update(_issue)
        super

        save_requirement
      end

      private

      def handle_iteration_change(issue)
        return unless issue.previous_changes.include?('sprint_id')

        send_iteration_change_notification(issue)
      end

      def handle_weight_change(issue)
        return unless issue.previous_changes.key?(:weight)

        ::GraphqlTriggers.issuable_weight_updated(issue)
      end

      def send_iteration_change_notification(issue)
        if issue.iteration.nil?
          notification_service.async.removed_iteration_issue(issue, current_user)
        else
          notification_service.async.changed_iteration_issue(issue, issue.iteration, current_user)
        end
      end

      override :do_handle_issue_type_change
      def do_handle_issue_type_change(issue)
        super

        ::IncidentManagement::Incidents::CreateSlaService.new(issue, current_user).execute

        issue.pending_escalations.delete_all(:delete_all) unless issue.supports_escalation?
      end

      def handle_promotion(issue)
        return unless params.delete(:promote_to_epic)

        Epics::IssuePromoteService.new(project: issue.project, current_user: current_user).execute(issue)
      end
    end
  end
end
