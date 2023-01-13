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
            ::Gitlab::UsageDataCounters::IssueActivityUniqueCounter.track_issue_changed_epic_action(author: current_user,
                                                                                                    project: project)
          else
            ::Gitlab::UsageDataCounters::IssueActivityUniqueCounter.track_issue_added_to_epic_action(author: current_user,
                                                                                                     project: project)
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

        unless can?(current_user, :read_epic, epic) && can?(current_user, :admin_issue_relation, issue)
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
          ::Iteration.of_groups(groups).find_by_id(params[:sprint_id])

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

      private

      def validate_iteration_params!(iteration_params)
        if iteration_params.values_at(:iteration_id, :sprint_id).all?(&:present?)
          raise IterationAssignmentError, 'Incompatible arguments: iteration_id, sprint_id.'
        end

        return false if iteration_params.values_at(:iteration_wildcard_id, :iteration_id, :sprint_id).all?(&:blank?)

        if iteration_params[:iteration_wildcard_id].present? && iteration_params[:iteration_cadence_id].blank?
          raise IterationAssignmentError, 'iteration_cadence_id is required when iteration_wildcard_id is provided.'
        end

        if [iteration_params[:iteration_id], iteration_params[:iteration_wildcard_id]].all?(&:present?)
          raise IterationAssignmentError, 'Incompatible arguments: iteration_id, iteration_wildcard_id.'
        end

        if iteration_params.values_at(:sprint_id, :iteration_wildcard_id).all?(&:present?)
          raise IterationAssignmentError, 'Incompatible arguments: sprint_id, iteration_wildcard_id.'
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
        finder_params[:id] = iteration_params[:iteration_id].presence || iteration_params[:sprint_id]
        finder_params[:iteration_cadence_ids] = iteration_params[:iteration_cadence_id]

        iteration = IterationsFinder.new(current_user, finder_params.compact).execute.first

        return unless iteration && current_user.can?(:read_iteration, iteration)

        iteration
      end

      def process_iteration_id
        # These iteration params need to be removed unconditionally from params as they do not exist on the model
        iteration_params = params.extract!(:iteration_wildcard_id, :iteration_cadence_id, :iteration_id, :sprint_id)

        return unless project_group&.licensed_feature_available?(:iterations)
        return unless validate_iteration_params!(iteration_params)

        iteration = find_iteration!(iteration_params, project_group)

        params[:iteration] = iteration if iteration
      end
    end
  end
end
