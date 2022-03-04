# frozen_string_literal: true

module EE
  module Boards
    module Issues
      module ListService
        extend ::Gitlab::Utils::Override

        override :filter
        def filter(issues)
          return issues if params[:all_lists]

          unless list&.movable? || list&.closed?
            issues = without_assignees_from_lists(issues)
            issues = without_milestones_from_lists(issues)
            issues = without_iterations_from_lists(issues)
          end

          case list&.list_type
          when 'assignee'
            with_assignee(super)
          when 'milestone'
            with_milestone(super)
          when 'iteration'
            with_iteration(super)
          else
            super
          end
        end

        override :label_links
        # rubocop: disable CodeReuse/ActiveRecord
        def label_links(label_ids)
          if has_valid_milestone?
            super.where(issues: { milestone_id: board.milestone_id })
          else
            super
          end
        end
        # rubocop: enable CodeReuse/ActiveRecord

        private

        # rubocop: disable CodeReuse/ActiveRecord
        def all_assignee_lists
          if parent.feature_available?(:board_assignee_lists)
            board.lists.assignee.where.not(user_id: nil)
          else
            ::List.none
          end
        end
        # rubocop: enable CodeReuse/ActiveRecord

        # rubocop: disable CodeReuse/ActiveRecord
        def all_milestone_lists
          if parent.feature_available?(:board_milestone_lists)
            board.lists.milestone.where.not(milestone_id: nil)
          else
            ::List.none
          end
        end
        # rubocop: enable CodeReuse/ActiveRecord

        # rubocop: disable CodeReuse/ActiveRecord
        def all_iteration_lists
          # Note that the names are very similar but these are different.
          # One is a license name and the other is a feature flag
          if parent.feature_available?(:board_iteration_lists)
            board.lists.iteration.where.not(iteration_id: nil)
          else
            ::List.none
          end
        end
        # rubocop: enable CodeReuse/ActiveRecord

        # rubocop: disable CodeReuse/ActiveRecord
        def without_assignees_from_lists(issues)
          return issues if all_assignee_lists.empty?

          matching_assignee = ::IssueAssignee
                                .where(user_id: all_assignee_lists.reorder(nil).select(:user_id))
                                .where("issue_id = issues.id")
                                .select(1)

          issues.where('NOT EXISTS (?)', matching_assignee)
        end
        # rubocop: enable CodeReuse/ActiveRecord

        override :metadata_fields
        def metadata_fields(required_fields)
          fields = super

          fields[:total_weight] = 'COALESCE(SUM(weight), 0)' if required_fields.include?(:total_issue_weight)

          fields
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def without_milestones_from_lists(issues)
          return issues if all_milestone_lists.empty?

          issues.where("milestone_id NOT IN (?) OR milestone_id IS NULL",
                       all_milestone_lists.select(:milestone_id))
        end
        # rubocop: enable CodeReuse/ActiveRecord

        # rubocop: disable CodeReuse/ActiveRecord
        def without_iterations_from_lists(issues)
          return issues if all_iteration_lists.empty?

          issues.not_in_iterations(all_iteration_lists.select(:iteration_id))
        end
        # rubocop: enable CodeReuse/ActiveRecord

        def with_assignee(issues)
          issues.assigned_to(list.user)
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def with_milestone(issues)
          issues.where(milestone_id: list.milestone_id)
        end
        # rubocop: enable CodeReuse/ActiveRecord

        def with_iteration(issues)
          issues.in_iterations(list.iteration_id)
        end

        # Prevent filtering by milestone stubs
        # like Milestone::Upcoming, Milestone::Started etc
        def has_valid_milestone?
          return false unless board.milestone

          !::Milestone.predefined?(board.milestone)
        end
      end
    end
  end
end
