# frozen_string_literal: true

module Boards
  class MilestonesController < Boards::ApplicationController
    include BoardsResponses

    before_action :authorize_read_milestone, only: [:index]
    feature_category :team_planning

    def index
      milestones_finder = Boards::MilestonesFinder.new(board, current_user)

      render json: MilestoneSerializer.new.represent(milestones_finder.execute)
    end
  end
end
