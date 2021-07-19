# frozen_string_literal: true

module EE
  module Boards
    module Lists
      module CreateService
        extend ::Gitlab::Utils::Override

        include MaxLimits

        override :execute
        def execute(board)
          return ServiceResponse.error(message: 'iteration_board_lists feature flag is disabled') if type == :iteration && ::Feature.disabled?(:iteration_board_lists, board.resource_parent, default_enabled: :yaml)
          return license_validation_error unless valid_license?(board.resource_parent)

          super
        end

        private

        def valid_license?(parent)
          List::LICENSED_LIST_TYPES.exclude?(type) || parent.feature_available?(:"board_#{type}_lists")
        end

        def license_validation_error
          message = case type
                    when :assignee
                      _('Assignee lists not available with your current license')
                    when :milestone
                      _('Milestone lists not available with your current license')
                    when :iteration
                      _('Iteration lists not available with your current license')
                    end

          ServiceResponse.error(message: message)
        end

        override :type
        def type
          # We don't ever expect to have more than one list
          # type param at once.
          if params.key?('assignee_id')
            :assignee
          elsif params.key?('milestone_id')
            :milestone
          elsif params.key?('iteration_id')
            :iteration
          else
            super
          end
        end

        override :target
        def target(board)
          strong_memoize(:target) do
            case type
            when :assignee
              find_user(board)
            when :milestone
              find_milestone(board)
            when :iteration
              find_iteration(board)
            else
              super
            end
          end
        end

        override :create_list_attributes
        def create_list_attributes(type, target, position)
          return super unless wip_limits_available?

          super.merge(
            max_issue_count: max_issue_count_by_params,
            max_issue_weight: max_issue_weight_by_params,
            limit_metric: limit_metric_by_params
          )
        end

        def find_milestone(board)
          milestones = milestone_finder(board).execute
          milestones.find_by(id: params['milestone_id']) # rubocop: disable CodeReuse/ActiveRecord
        end

        def find_iteration(board)
          parent_params = { parent: board.resource_parent, include_ancestors: true }
          ::IterationsFinder.new(current_user, parent_params).find_by(id: params['iteration_id']) # rubocop: disable CodeReuse/ActiveRecord
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def find_user(board)
          user_ids = user_finder(board).execute.reselect(:user_id)
          ::User.id_in(user_ids).find_by(id: params['assignee_id'])
        end
        # rubocop: enable CodeReuse/ActiveRecord

        def milestone_finder(board)
          @milestone_finder ||= ::Boards::MilestonesFinder.new(board, current_user)
        end

        def user_finder(board)
          @user_finder ||= ::Boards::UsersFinder.new(board, current_user)
        end

        def wip_limits_available?
          parent.feature_available?(:wip_limits)
        end

        def limit_metric_by_params
          params[:limit_metric]
        end
      end
    end
  end
end
