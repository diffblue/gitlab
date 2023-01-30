# frozen_string_literal: true

module Onboarding
  class LearnGitlab
    PROJECT_NAME = 'Learn GitLab'
    PROJECT_NAME_ULTIMATE_TRIAL = 'Learn GitLab - Ultimate trial'
    BOARD_NAME = 'GitLab onboarding'
    LABEL_NAME = 'Novice'
    TEMPLATE_NAME = 'learn_gitlab_ultimate.tar.gz'

    def initialize(current_user)
      @current_user = current_user
    end

    def onboarding_and_available?(namespace)
      return false unless current_user && project

      Onboarding::Progress.onboarding?(namespace) && available?
    end

    def project
      @project ||= current_user.projects.find_by_name([PROJECT_NAME, PROJECT_NAME_ULTIMATE_TRIAL])
    end

    def board
      return unless project

      @board ||= project.boards.find_by_name(BOARD_NAME)
    end

    def label
      return unless project

      @label ||= project.labels.find_by_name(LABEL_NAME)
    end

    private

    attr_reader :current_user

    def available?
      project.present? && board.present? && label.present?
    end
  end
end
