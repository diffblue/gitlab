# frozen_string_literal: true

module IterationCadencesActions
  extend ActiveSupport::Concern

  included do
    before_action :authorize_show_cadence!, only: [:index]
    before_action :set_noteable_type, only: [:index]

    feature_category :team_planning
    urgency :low
  end

  def index; end

  private

  def authorize_show_cadence!
    render_404 unless can?(current_user, :read_iteration_cadence, group)
  end

  def set_noteable_type
    @noteable_type = Iteration # rubocop:disable Gitlab/ModuleWithInstanceVariables
  end
end
