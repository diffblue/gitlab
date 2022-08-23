# frozen_string_literal: true

class Groups::IterationsController < Groups::ApplicationController
  before_action :check_iterations_available!
  before_action :authorize_show_iteration!, only: [:index, :show]
  before_action :authorize_create_iteration!, only: [:new, :edit]
  before_action :set_noteable_type, only: [:show, :new, :edit]
  before_action :set_iteration!, only: [:show, :edit]

  feature_category :team_planning
  urgency :low

  def index
    redirect_to group_iteration_cadences_path(group)
  end

  def show
    redirect_to group_iteration_cadence_iteration_path(iteration_cadence_id: cadence_id, id: params[:id])
  end

  def new
    redirect_to group_iteration_cadences_path(group)
  end

  def edit
    redirect_to edit_group_iteration_cadence_iteration_path(iteration_cadence_id: cadence_id, id: params[:id])
  end

  private

  def set_iteration!
    @iteration ||= IterationsFinder
      .new(current_user, id: params[:id], parent: group, include_ancestors: true)
      .execute
      .first

    render_404 if @iteration.nil?
  end

  def cadence_id
    @iteration.iterations_cadence.id
  end

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
