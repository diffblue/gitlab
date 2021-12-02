# frozen_string_literal: true

module EE
  module Boards
    module Issues
      module MoveService
        extend ::Gitlab::Utils::Override

        override :execute
        def execute(issue)
          unless assignee_authorized_for?(issue)
            return error(issue, 'Not authorized to assign issue to list user')
          end

          super
        end

        override :issuable_params
        def issuable_params(issue)
          args = super
          args[:epic_id] = params[:epic_id] if params.has_key?(:epic_id)

          return args unless move_between_lists?

          unless both_are_same_type? || !moving_to_list.movable?
            args.delete(:remove_label_ids)
          end

          args.merge(list_movement_args(issue))
        end

        def assignee_authorized_for?(issue)
          return true unless moving_to_list&.assignee?

          Ability.allowed?(moving_to_list.user, :read_issue, issue)
        end

        def both_are_list_type?(type)
          return false unless moving_from_list.list_type == type

          both_are_same_type?
        end

        def both_are_same_type?
          moving_from_list.list_type == moving_to_list.list_type
        end

        def list_movement_args(issue)
          assignee_ids = assignee_ids(issue)
          milestone_id = milestone_id(issue)

          movement_args = {
            assignee_ids: assignee_ids,
            milestone_id: milestone_id
          }

          movement_args[:sprint_id] = iteration_id(issue)

          movement_args
        end

        def milestone_id(issue)
          return if moving_to_list.backlog? && moving_from_list.milestone?
          return moving_to_list.milestone_id if moving_to_list.milestone?

          issue.milestone_id
        end

        def iteration_id(issue)
          return if moving_to_list.backlog? && moving_from_list.iteration?
          return moving_to_list.iteration_id if moving_to_list.iteration?

          issue.sprint_id
        end

        def assignee_ids(issue)
          assignees = (issue.assignee_ids + [moving_to_list.user_id]).compact

          assignees -= [moving_from_list.user_id] if both_are_list_type?('assignee') || moving_to_list.backlog?

          assignees
        end
      end
    end
  end
end
