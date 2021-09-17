# frozen_string_literal: true

module EE
  module Boards
    module BaseService
      # rubocop: disable CodeReuse/ActiveRecord
      def filter_assignee
        return unless params.key?(:assignee_id)

        assignee = ::User.find_by(id: params.delete(:assignee_id))
        params.merge!(assignee: assignee)
      end
      # rubocop: enable CodeReuse/ActiveRecord

      # rubocop: disable CodeReuse/ActiveRecord
      def filter_milestone
        return if params[:milestone_id].blank?
        return if ::Milestone::Predefined::ALL.map(&:id).include?(params[:milestone_id].to_i)

        finder_params = { group_ids: group&.self_and_ancestors }
        finder_params[:project_ids] = [parent.id] if parent.is_a?(Project)

        milestone = ::MilestonesFinder.new(finder_params).find_by(id: params[:milestone_id])

        params.delete(:milestone_id) unless milestone
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def filter_iteration_and_iteration_cadence
        return if params[:iteration_id].blank? && params[:iteration_cadence_id].blank?

        if params[:iteration_id].present? && !wildcard_iteration_id?
          filter_iteration
        else
          filter_iteration_cadence
        end

        ensure_iteration_cadence if wildcard_iteration_id?
      end

      def filter_labels
        if params.key?(:label_ids)
          params[:label_ids] = (labels_service.filter_labels_ids_in_param(:label_ids) || [])
        elsif params.key?(:labels)
          params[:label_ids] = (labels_service.find_or_create_by_titles.map(&:id) || [])
        end
      end

      def labels_service
        @labels_service ||= ::Labels::AvailableLabelsService.new(current_user, parent, params)
      end

      private

      def filter_iteration
        iteration = IterationsFinder.new(current_user, iterations_finder_params).execute.first

        if !iteration
          params.delete(:iteration_id)
          params.delete(:iteration_cadence_id)
        else
          params[:iteration_cadence_id] = iteration.iterations_cadence_id
        end
      end

      def filter_iteration_cadence
        return if params[:iteration_cadence_id].blank?

        cadence = Iterations::CadencesFinder.new(current_user, group, { include_ancestor_groups: true, id: params[:iteration_cadence_id] }).execute.first

        params.delete(:iteration_cadence_id) unless cadence
      end

      # todo: enforce iteration_cadence_id before we make multiple iteration cadences GA
      # https://gitlab.com/gitlab-org/gitlab/-/issues/323653
      def ensure_iteration_cadence
        return if params[:iteration_cadence_id].present?

        cadence = Iterations::CadencesFinder.new(current_user, group, { include_ancestor_groups: true }).execute.first

        wildcard_iteration_title = ::Iteration::Predefined.by_id(params[:iteration_id].to_i)&.name&.upcase
        raise ArgumentError, "No cadence could be found to scope board to #{wildcard_iteration_title} iteration." unless cadence
      end

      def wildcard_iteration_id?
        return false if params[:iteration_id].blank?

        ::Iteration::Predefined::ALL.map(&:id).include?(params[:iteration_id].to_i)
      end

      def group
        case parent
        when Group
          parent
        when Project
          parent.group
        end
      end

      def iterations_finder_params
        { parent: parent, include_ancestors: true, state: 'all', id: params[:iteration_id] }
      end
    end
  end
end
