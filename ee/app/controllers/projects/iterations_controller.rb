# frozen_string_literal: true

class Projects::IterationsController < Projects::ApplicationController
  before_action :check_iterations_available!
  before_action :authorize_show_iteration!

  feature_category :team_planning

  def index; end

  def show; end

  private

  def check_iterations_available!
    render_404 unless project.feature_available?(:iterations)
  end

  def authorize_show_iteration!
    render_404 unless can?(current_user, :read_iteration, project)
  end
end
