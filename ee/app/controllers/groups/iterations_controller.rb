# frozen_string_literal: true

class Groups::IterationsController < Groups::ApplicationController
  before_action :check_iterations_available!
  before_action :authorize_show_iteration!, only: [:index, :show]
  before_action :authorize_create_iteration!, only: [:new, :edit]
  before_action :set_noteable_type, only: [:show, :new, :edit]

  feature_category :team_planning

  def index; end

  def show; end

  def new; end

  def edit; end

  private

  def set_noteable_type
    @noteable_type = Iteration
  end

  def check_iterations_available!
    render_404 unless group.licensed_feature_available?(:iterations)
  end

  def authorize_create_iteration!
    render_404 unless can?(current_user, :create_iteration, group)
  end

  def authorize_show_iteration!
    render_404 unless can?(current_user, :read_iteration, group)
  end
end
