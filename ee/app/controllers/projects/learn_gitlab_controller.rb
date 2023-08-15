# frozen_string_literal: true

module Projects
  class LearnGitlabController < Projects::ApplicationController
    include OneTrustCSP
    include GoogleAnalyticsCSP

    before_action :authenticate_user! # since it is skipped in inherited controller
    before_action :owner_access!, only: :onboarding
    before_action :verify_learn_gitlab_available!, only: :show
    before_action only: :onboarding do
      push_frontend_feature_flag(:gitlab_gtm_datalayer, type: :ops)
    end

    helper_method :onboarding_status

    feature_category :onboarding
    urgency :low, [:show]

    def show; end

    def onboarding
      cookies[:confetti_post_signup] = true

      render layout: 'minimal'
    end

    private

    def verify_learn_gitlab_available!
      access_denied! unless ::Onboarding::LearnGitlab.available?(project.namespace, current_user)
    end

    def owner_access!
      access_denied! unless can?(current_user, :owner_access, project)
    end

    def onboarding_status
      ::Onboarding::Status.new(params, session, current_user)
    end
    strong_memoize_attr :onboarding_status
  end
end
