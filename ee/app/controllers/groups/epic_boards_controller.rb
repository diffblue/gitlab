# frozen_string_literal: true
class Groups::EpicBoardsController < Groups::ApplicationController
  include BoardsActions
  include RecordUserLastActivity
  include ProductAnalyticsTracking
  include Gitlab::Utils::StrongMemoize
  extend ::Gitlab::Utils::Override

  before_action do
    push_frontend_feature_flag(:epic_color_highlight, group)
    push_frontend_feature_flag(:apollo_boards, group)
  end

  before_action do
    push_frontend_feature_flag(:epic_color_highlight, group)
  end

  track_event :index, :show, name: 'g_project_management_users_viewing_epic_boards'

  feature_category :portfolio_management
  urgency :default, [:index, :show]

  private

  override :redirect_to_recent_board
  def redirect_to_recent_board
    return unless latest_visited_board

    redirect_to group_epic_board_path(group, latest_visited_board.epic_board)
  end

  override :latest_visited_board
  def latest_visited_board
    @latest_visited_board ||= Boards::EpicBoardsVisitsFinder.new(parent, current_user).latest
  end

  override :board_visit_service
  def board_visit_service
    Boards::EpicBoards::Visits::CreateService
  end

  def board_finder
    strong_memoize :board_finder do
      ::Boards::EpicBoardsFinder.new(parent, id: params[:id])
    end
  end

  def board_create_service
    strong_memoize :board_create_service do
      ::Boards::EpicBoards::CreateService.new(parent, current_user)
    end
  end

  def authorize_read_board!
    access_denied! unless can?(current_user, :read_epic_board, group)
  end
end
