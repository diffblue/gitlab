# frozen_string_literal: true

module EE
  module BoardsHelper
    extend ::Gitlab::Utils::Override

    override :board_list_data
    def board_list_data
      super.merge(list_milestone_path: board_milestones_path(board, :json),
                  list_assignees_path: board_users_path(board, :json))
    end

    # rubocop:disable Metrics/AbcSize
    override :board_data
    def board_data
      show_feature_promotion = @project && show_promotions? &&
                               !@project.feature_available?(:scoped_issue_board)

      data = {
        board_milestone_title: board.milestone&.name,
        board_milestone_id: board.milestone_id,
        board_iteration_title: board.iteration&.title,
        board_iteration_id: board.iteration_id,
        board_assignee_username: board.assignee&.username,
        board_assignee_id: board.assignee&.id,
        label_ids: board.label_ids,
        labels: board.labels.to_json(only: [:id, :title, :color, :text_color] ),
        board_weight: board.weight,
        show_promotion: show_feature_promotion,
        can_update: can_update?.to_s,
        can_admin_list: can_admin_list?.to_s,
        disabled: board.disabled_for?(current_user).to_s,
        emails_disabled: current_board_parent.emails_disabled?.to_s
      }

      super.merge(data).merge(licensed_features).merge(group_level_features)
    end

    def licensed_features
      # These features are available at both project- and group-level
      {
        multiple_assignees_feature_available: current_board_parent.feature_available?(:multiple_issue_assignees).to_s,
        weight_feature_available: current_board_parent.feature_available?(:issue_weights).to_s,
        milestone_lists_available: current_board_parent.feature_available?(:board_milestone_lists).to_s,
        assignee_lists_available: current_board_parent.feature_available?(:board_assignee_lists).to_s,
        scoped_labels: current_board_parent.feature_available?(:scoped_labels)&.to_s
      }
    end

    def group_level_features
      {
        iteration_lists_available: current_board_namespace.feature_available?(:board_iteration_lists).to_s,
        epic_feature_available: current_board_namespace.feature_available?(:epics).to_s,
        iteration_feature_available: current_board_namespace.feature_available?(:iterations).to_s,
        sub_epics_feature_available: current_board_namespace.feature_available?(:subepics).to_s
      }
    end
    # rubocop:enable Metrics/AbcSize

    override :can_update?
    def can_update?
      return can?(current_user, :admin_epic, board) if board.is_a?(::Boards::EpicBoard)

      super
    end

    override :can_admin_list?
    def can_admin_list?
      return can?(current_user, :admin_epic_board_list, current_board_parent) if board.is_a?(::Boards::EpicBoard)

      super
    end

    override :build_issue_link_base
    def build_issue_link_base
      return group_epics_path(@group) if board.is_a?(::Boards::EpicBoard)

      super
    end

    override :board_base_url
    def board_base_url
      return group_epic_boards_url(@group) if board.is_a?(::Boards::EpicBoard)

      super
    end
  end
end
