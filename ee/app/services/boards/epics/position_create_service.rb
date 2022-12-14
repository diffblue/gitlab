# frozen_string_literal: true

module Boards
  module Epics
    class PositionCreateService < Boards::BaseService
      include Gitlab::Utils::StrongMemoize

      LIMIT = 100

      def execute
        validate_params!
        time = DateTime.current

        positions = epics_on_board_list.map.with_index(1) do |list_epic, index|
          Boards::EpicBoardPosition.new(
            epic_id: list_epic.id,
            epic_board_id: board_id,
            relative_position: start_position + Boards::EpicBoardPosition::IDEAL_DISTANCE * index,
            created_at: time,
            updated_at: time
          )
        end

        return if positions.empty?

        Boards::EpicBoardPosition.bulk_upsert(positions)
      end

      private

      def validate_params!
        raise ArgumentError, 'board_id param is missing' if params[:board_id].blank?
        raise ArgumentError, 'list_id param is missing' if params[:list_id].blank?
      end

      def start_position
        strong_memoize(:start_position) do
          last_board_position = Boards::EpicBoardPosition.last_for_board_id(board_id)
          base = last_board_position&.relative_position || Boards::EpicBoardPosition::START_POSITION
          base + Boards::EpicBoardPosition::IDEAL_DISTANCE
        end
      end

      def epics_on_board_list
        # the positions will be created for all epics in the board list
        # which don't have position set yet and which appear in the list
        # before the epic being positioned. Epics w/o position are ordered
        # by ID in descending order so we need to set position for epics with
        # id >= from_id
        list_params = { board_id: board_id, id: list_id, from_id: params[:from_id], exclude_positioned: true }

        Boards::Epics::ListService.new(parent, current_user, list_params).execute
          .select(:id)
          .limit(LIMIT)
      end

      def board_id
        @board_id ||= params.delete(:board_id)
      end

      def list_id
        @list_id ||= params.delete(:list_id)
      end
    end
  end
end
