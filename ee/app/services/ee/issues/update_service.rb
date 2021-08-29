# frozen_string_literal: true

module EE
  module Issues
    module UpdateService
      extend ::Gitlab::Utils::Override
      include ::Gitlab::Utils::StrongMemoize

      override :filter_params
      def filter_params(issue)
        params.delete(:skip_auth)
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

      override :can_admin_issuable?
      def can_admin_issuable?(issuable)
        skip_auth || super
      end

      override :handle_changes
      def handle_changes(issue, _options)
        super

        handle_iteration_change(issue)
      end

      override :before_update
      def before_update(issue, **args)
        super

        # This is part of the migration from Requirement (the first class object)
        # to Issue/Work Item (of type Requirement).
        # We can't wrap the change in a Transaction (see https://gitlab.com/gitlab-org/gitlab/-/merge_requests/64929#note_647123684)
        # so we'll check if both are valid before saving

        # Don't bother syncing if it's possibly spam
        return if issue.spam? || !issue.requirement

        # Keep requirement objects in sync: gitlab-org/gitlab#323779
        self.requirement_to_sync = prepare_requirement_for_sync(issue)
        return unless requirement_to_sync

        # This prevents the issue from being saveable
        issue.requirement_sync_error! unless requirement_to_sync.valid?
      end

      override :after_update
      def after_update(_issue)
        super

        return unless requirement_to_sync

        unless requirement_to_sync.save
          # We checked that it was valid earlier but it still did not save. Uh oh.
          # This requires a manual re-sync and an investigation as to why this happened.
          ::Gitlab::AppLogger.info(message: "Requirement-Issue Sync: Associated requirement could not be saved", project_id: project.id, user_id: current_user.id, params: params)
        end
      end

      private

      attr_accessor :skip_auth, :requirement_to_sync

      def handle_iteration_change(issue)
        return unless issue.previous_changes.include?('sprint_id')

        send_iteration_change_notification(issue)
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
      end

      def handle_promotion(issue)
        return unless params.delete(:promote_to_epic)

        Epics::IssuePromoteService.new(project: issue.project, current_user: current_user).execute(issue)
      end

      def prepare_requirement_for_sync(issue)
        sync_params = RequirementsManagement::Requirement.sync_params
        sync_attrs = issue.attributes.with_indifferent_access.slice(*sync_params)

        # Update the requirement manually rather than through RequirementsManagement::Requirement::UpdateService,
        # so the sync happens even if the Requirements feature is no longer available via the license.
        requirement = issue.requirement
        requirement.assign_attributes(sync_attrs)
        requirement if requirement.changed?
      end
    end
  end
end
