# frozen_string_literal: true

module Registrations
  class VerificationController < ApplicationController
    layout 'minimal'

    before_action :check_if_gl_com_or_dev
    feature_category :onboarding

    before_action :publish_experiment, :set_next_step_url

    def new; end

    private

    def publish_experiment
      experiment(:registration_verification, user: current_user).publish
    end

    def set_next_step_url
      @next_step_url = if params[:project_id].present?
                         continuous_onboarding_getting_started_users_sign_up_welcome_path(
                           params.slice(:project_id).permit!
                         )
                       else
                         root_path
                       end
    end
  end
end
