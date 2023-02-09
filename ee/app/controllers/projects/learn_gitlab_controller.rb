# frozen_string_literal: true

module Projects
  class LearnGitlabController < Projects::ApplicationController
    include OneTrustCSP
    include GoogleAnalyticsCSP

    before_action :authenticate_user! # since it is skipped in inherited controller
    before_action :owner_access!, only: :onboarding
    before_action :verify_learn_gitlab_available!, only: :show
    before_action :enable_invite_for_help_continuous_onboarding_experiment, only: :show
    before_action :enable_video_tutorials_continuous_onboarding_experiment, only: :show
    before_action only: :onboarding do
      push_frontend_feature_flag(:gitlab_gtm_datalayer, type: :ops)
    end

    feature_category :user_profile
    urgency :low, [:show]

    def show; end

    def onboarding
      cookies[:confetti_post_signup] = true

      @track_label = helpers.in_trial_onboarding_flow? ? 'trial_registration' : 'free_registration'
      ::Gitlab::Tracking.event(self.class.name, 'onboarding', user: current_user, label: @track_label)

      render layout: 'minimal'
    end

    private

    def verify_learn_gitlab_available!
      access_denied! unless Onboarding::LearnGitlab.new(current_user).onboarding_and_available?(project.namespace)
    end

    def owner_access!
      access_denied! unless can?(current_user, :owner_access, project)
    end

    def enable_invite_for_help_continuous_onboarding_experiment
      return unless current_user.can?(:admin_group_member, project.namespace)

      experiment(:invite_for_help_continuous_onboarding, namespace: project.namespace) do |e|
        e.candidate {}
      end
    end

    def enable_video_tutorials_continuous_onboarding_experiment
      experiment(:video_tutorials_continuous_onboarding, namespace: project&.namespace).publish
    end
  end
end
