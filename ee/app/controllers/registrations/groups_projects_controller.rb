# frozen_string_literal: true

# TODO: remove after the deployment
# https://gitlab.com/gitlab-org/gitlab/-/issues/411208
module Registrations
  class GroupsProjectsController < ApplicationController
    feature_category :onboarding

    # redirect post requests for stale pages during release of new code/routes
    def create
      redirect_to new_users_sign_up_group_path(permitted_params)
    end

    def import
      redirect_to new_users_sign_up_group_path
    end

    private

    def permitted_params
      params.permit(:trial_onboarding_flow, :glm_source, :glm_content, :trial)
    end
  end
end
