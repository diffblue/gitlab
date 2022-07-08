# frozen_string_literal: true

module EE
  module Issues
    module BaseService
      extend ::Gitlab::Utils::Override

      EpicAssignmentError = Class.new(::ArgumentError)
      IterationAssignmentError = Class.new(StandardError)

      ALLOWED_ITERATION_WILDCARDS = [::Iteration::Predefined::Current.title].freeze

      def filter_epic(issue)
        return unless epic_param_present?

        epic = epic_param(issue)

        params[:confidential] = true if !issue.persisted? && epic&.confidential
        params[:epic] = epic
      end

      def assign_epic(issue, epic)
        had_epic = issue.epic.present?

        link_params = { target_issuable: issue, skip_epic_dates_update: true }

        EpicIssues::CreateService.new(epic, current_user, link_params).execute.tap do |result|
          next unless result[:status] == :success

          if had_epic
            ::Gitlab::UsageDataCounters::IssueActivityUniqueCounter.track_issue_changed_epic_action(author: current_user, project: project)
          else
            ::Gitlab::UsageDataCounters::IssueActivityUniqueCounter.track_issue_added_to_epic_action(author: current_user, project: project)
          end
        end
      end

      def unassign_epic(issue)
        link = EpicIssue.find_by_issue_id(issue.id)
        return success unless link

        EpicIssues::DestroyService.new(link, current_user).execute.tap do |result|
          next unless result[:status] == :success

          ::Gitlab::UsageDataCounters::IssueActivityUniqueCounter.track_issue_removed_from_epic_action(author: current_user,
                                                                                                       project: project)
        end
      end

      def epic_param(issue)
        epic_id = params.delete(:epic_id)
        epic = params.delete(:epic) || find_epic(issue, epic_id)

        return unless epic

        unless can?(current_user, :read_epic, epic) && can?(current_user, :admin_issue, issue)
          raise ::Gitlab::Access::AccessDeniedError
        end

        epic
      end

      def find_epic(issue, epic_id)
        return if epic_id.to_i == 0

        group = issue.project.group
        return unless group.present?

        EpicsFinder.new(current_user, group_id: group.id,
                        include_ancestor_groups: true).find(epic_id)
      end

      def epic_param_present?
        params.key?(:epic) || params.key?(:epic_id)
      end

      def filter_iteration
        return unless params[:sprint_id]
        return params[:sprint_id] = '' if params[:sprint_id] == IssuableFinder::Params::NONE

        groups = project.group&.self_and_ancestors&.select(:id)

        iteration =
          ::Iteration.for_projects_and_groups([project.id], groups).find_by_id(params[:sprint_id])

        params[:sprint_id] = '' unless iteration
      end

      override :handle_changes
      def handle_changes(issue, options)
        handle_epic_change(issue, options)
      end

      def handle_epic_change(issue, options)
        return unless epic_param_present?

        old_epic = issue.epic
        epic = options.dig(:params, :epic)

        return if !epic && !old_epic

        result = if old_epic && !epic
                   unassign_epic(issue)
                 else
                   assign_epic(issue, epic)
                 end

        issue.reload_epic

        if result[:status] == :error
          raise EpicAssignmentError, result[:message]
        end
      end

      # This is part IIb(sync state updates) of the migration from
      # Requirement (the first class object) to Issue/Work Item (of type Requirement).
      # https://gitlab.com/gitlab-org/gitlab/-/issues/323779
      def sync_requirement_state(issue, state, &block)
        return yield unless issue.requirement?

        requirement = issue.requirement

        return yield unless requirement # no need to use transaction if there is no requirement to sync

        ::Issue.transaction do
          requirement.state = state
          requirement.save!

          state == 'archived' ? issue.close!(current_user) : issue.reopen!
        rescue StandardError => e
          ::Gitlab::AppLogger.info(
            message: 'Requirement-Issue state Sync: Associated requirement could not be saved',
            error: e.message,
            project_id: project.id,
            user_id: current_user.id,
            requirement_id: requirement.id,
            issue_id: issue.id,
            state: state
          )

          false
        end
      end

      private

      def validate_iteration_params!(iteration_params)
        return false if [iteration_params[:iteration_wildcard_id], iteration_params[:iteration_id]].all?(&:blank?)

        if iteration_params[:iteration_wildcard_id].present? && iteration_params[:iteration_cadence_id].blank?
          raise IterationAssignmentError, 'iteration_cadence_id is required when iteration_wildcard_id is provided.'
        end

        if [iteration_params[:iteration_id], iteration_params[:iteration_wildcard_id]].all?(&:present?)
          raise IterationAssignmentError, 'Incompatible arguments: iteration_id, iteration_wildcard_id.'
        end

        if iteration_params[:iteration_wildcard_id].present?
          ALLOWED_ITERATION_WILDCARDS.any? { |wildcard| iteration_params[:iteration_wildcard_id].casecmp?(wildcard) }
        else
          true
        end
      end

      def find_iteration!(iteration_params, group)
        # converts params to keys the finder understands
        finder_params = iteration_params.slice(:iteration_wildcard_id).merge(parent: group, include_ancestors: true)
        finder_params[:id] = iteration_params[:iteration_id]
        finder_params[:iteration_cadence_ids] = iteration_params[:iteration_cadence_id]

        iteration = IterationsFinder.new(current_user, finder_params.compact).execute.first

        return unless iteration && current_user.can?(:read_iteration, iteration)

        iteration
      end

      def process_iteration_id
        # These iteration params need to be removed unconditionally from params as they do not exist on the model
        iteration_params = params.extract!(:iteration_wildcard_id, :iteration_cadence_id, :iteration_id)

        return unless project_group&.licensed_feature_available?(:iterations)
        return unless validate_iteration_params!(iteration_params)

        iteration = find_iteration!(iteration_params, project_group)

        params[:iteration] = iteration if iteration
      end

      attr_accessor :requirement_to_sync

      def assign_requirement_to_be_synced_for(issue)
        # This is part of the migration from Requirement (the first class object)
        # to Issue/Work Item (of type Requirement).
        # We can't wrap the change in a Transaction (see https://gitlab.com/gitlab-org/gitlab/-/merge_requests/64929#note_647123684)
        # so we'll check if both are valid before saving

        # Don't bother syncing if it's possibly spam
        return if issue.spam?
        return unless issue.requirement?

        # Keep requirement objects in sync: gitlab-org/gitlab#323779
        self.requirement_to_sync = assign_requirement_attributes(issue)

        return unless requirement_to_sync

        # This prevents the issue from being saveable
        issue.requirement ||= requirement_to_sync
        issue.requirement_sync_error! unless requirement_to_sync.valid?
      end

      def save_requirement
        return unless requirement_to_sync

        unless requirement_to_sync.save
          # We checked that it was valid earlier but it still did not save. Uh oh.
          # This requires a manual re-sync and an investigation as to why this happened.
          log_params = params.slice(*RequirementsManagement::Requirement.sync_params)

          ::Gitlab::AppLogger.info(
            message: "Requirement-Issue Sync: Associated requirement could not be saved",
            project_id: project.id,
            user_id: current_user.id,
            params: log_params
          )
        end
      end

      def assign_requirement_attributes(issue)
        sync_params = RequirementsManagement::Requirement.sync_params
        sync_attrs = issue.attributes.with_indifferent_access.slice(*sync_params)

        # Update or create the requirement manually rather than through RequirementsManagement::Requirement::UpdateService,
        # so the sync happens even if the Requirements feature is no longer available via the license.
        requirement = issue.requirement || RequirementsManagement::Requirement.new

        requirement.assign_attributes(sync_attrs.merge(requirement_issue: issue))

        requirement if requirement.changed?
      end
    end
  end
end
