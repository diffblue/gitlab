# frozen_string_literal: true

module Boards
  module EpicBoards
    class UpdateService < Boards::UpdateService
      include Gitlab::Utils::UsageData
      extend ::Gitlab::Utils::Override

      override :execute
      def execute(board)
        super.tap do
          if board.saved_change_to_name?
            track_usage_event(:g_project_management_users_updating_epic_board_names, current_user.id)
          end
        end
      end

      override :permitted_params
      def permitted_params
        permitted = PERMITTED_PARAMS

        if parent.feature_available?(:scoped_issue_board)
          permitted += %i(labels label_ids)
        end

        if Feature.enabled?(:epic_color_highlight, parent)
          permitted += %i(display_colors)
        end

        permitted
      end
    end
  end
end
