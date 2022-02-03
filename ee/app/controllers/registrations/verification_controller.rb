# frozen_string_literal: true

module Registrations
  class VerificationController < ApplicationController
    layout 'minimal'

    before_action :check_if_gl_com_or_dev
    feature_category :onboarding

    before_action :publish_experiment

    def new
    end

    private

    def publish_experiment
      experiment(:registration_verification, user: current_user).publish
    end
  end
end
