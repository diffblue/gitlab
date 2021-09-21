# frozen_string_literal: true

module Boards
  class EpicBoardPresenter < Gitlab::View::Presenter::Delegated
    presents ::Boards::EpicBoard, as: :epic_board
  end
end
