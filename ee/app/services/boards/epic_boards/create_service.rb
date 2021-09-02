# frozen_string_literal: true

module Boards
  module EpicBoards
    class CreateService < Boards::CreateService
      include Gitlab::Utils::UsageData
      extend ::Gitlab::Utils::Override

      override :can_create_board?
      def can_create_board?
        true
      end

      override :parent_board_collection
      def parent_board_collection
        parent.epic_boards
      end

      override :execute
      def execute
        super.tap do |response|
          if response.success?
            track_usage_event(:g_project_management_users_creating_epic_boards, current_user&.id)
          end
        end
      end
    end
  end
end
