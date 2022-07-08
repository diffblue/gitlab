# frozen_string_literal: true
class Groups::EpicBoardsController < Groups::ApplicationController
  include BoardsActions
  include RecordUserLastActivity
  include RedisTracking
  include Gitlab::Utils::StrongMemoize
  extend ::Gitlab::Utils::Override

  before_action :redirect_to_recent_board, only: [:index]
  before_action :assign_endpoint_vars
  before_action do
    push_frontend_feature_flag(:fe_epic_board_total_weight, group)
  end

  before_action do
    push_frontend_feature_flag(:realtime_labels, group)
    push_frontend_feature_flag(:epic_color_highlight, group)
  end

  track_redis_hll_event :index, :show, name: 'g_project_management_users_viewing_epic_boards'

  feature_category :portfolio_management
  urgency :default, [:index, :show]

  private

  def redirect_to_recent_board
    return if request.format.json? || !latest_visited_board

    redirect_to group_epic_board_path(group, latest_visited_board.epic_board)
  end

  def latest_visited_board
    @latest_visited_board ||= Boards::EpicBoardsVisitsFinder.new(parent, current_user).latest
  end

  override :board_visit_service
  def board_visit_service
    Boards::EpicBoards::Visits::CreateService
  end

  def board_klass
    ::Boards::EpicBoard
  end

  def boards_finder
    strong_memoize :boards_finder do
      ::Boards::EpicBoardsFinder.new(parent)
    end
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

  override :respond_with
  def respond_with(resource)
    # no JSON for epic boards
    respond_to do |format|
      format.html
    end
  end

  def assign_endpoint_vars
    @boards_endpoint = group_epic_boards_path(group)
  end

  def authorize_read_board!
    access_denied! unless can?(current_user, :read_epic_board, group)
  end
end
