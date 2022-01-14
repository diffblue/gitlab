# frozen_string_literal: true

module IterationCadencesActions
  extend ActiveSupport::Concern

  included do
    before_action :check_cadences_available!
    before_action :authorize_show_cadence!, only: [:index]
    before_action :set_noteable_type, only: [:index]

    feature_category :team_planning
  end

  def index; end

  private

  def check_cadences_available!
    render_404 unless group&.iteration_cadences_feature_flag_enabled?
  end

  def authorize_show_cadence!
    render_404 unless can?(current_user, :read_iteration_cadence, group)
  end

  def set_noteable_type
    @noteable_type = Iteration # rubocop:disable Gitlab/ModuleWithInstanceVariables
  end
end
