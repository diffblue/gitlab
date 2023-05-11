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
        handle_health_status_change(issue)
      end

      private

      def handle_iteration_change(issue)
        return unless issue.previous_changes.include?('sprint_id')

        send_iteration_change_notification(issue)
        ::GraphqlTriggers.issuable_iteration_updated(issue)
      end

      def handle_weight_change(issue)
        return unless issue.previous_changes.key?(:weight)

        ::GraphqlTriggers.issuable_weight_updated(issue)
      end

      def handle_health_status_change(issue)
        return unless issue.previous_changes.key?(:health_status)

        ::GraphqlTriggers.issuable_health_status_updated(issue)
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

        Epics::IssuePromoteService.new(container: issue.project, current_user: current_user).execute(issue)
      end

      def should_update_requirement_verification_status?(issuable)
        issuable.work_item_type.requirement? &&
          params[:last_test_report_state].present? &&
          can?(current_user, :create_requirement_test_report, issuable.project)
      end

      # Requirement verification status is being widgetized,
      # for now, this is needed to keep current requirement
      # GraphQL API compatible until its deprecation.
      # More information at https://gitlab.com/groups/gitlab-org/-/epics/7266
      def create_requirement_test_report_for(issuable)
        return unless should_update_requirement_verification_status?(issuable)

        test_report_state = RequirementsManagement::TestReport.states[params[:last_test_report_state]]

        test_report =
          RequirementsManagement::TestReport.build_report(
            requirement_issue: issuable,
            state: test_report_state,
            author: current_user
          )

        issuable.requirement_sync_error! unless test_report.save
      end

      override :transaction_update
      def transaction_update(issuable, opts = {})
        create_requirement_test_report_for(issuable)

        super
      end
    end
  end
end
