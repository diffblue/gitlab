# frozen_string_literal: true

module Registrations
  class GroupsProjectsController < ApplicationController
    include OneTrustCSP
    include GoogleAnalyticsCSP
    include Onboarding::SetRedirect

    skip_before_action :require_verification, only: :new
    skip_before_action :set_confirm_warning
    before_action :check_if_gl_com_or_dev
    before_action :authorize_create_group!, only: :new
    before_action :require_verification,
                  only: [:create, :import],
                  if: -> { current_user.requires_credit_card_verification }
    before_action only: [:new] do
      push_frontend_feature_flag(:gitlab_gtm_datalayer, type: :ops)
    end

    layout 'minimal'

    feature_category :onboarding

    def new
      experiment(:require_verification_for_namespace_creation, user: current_user) do |e|
        e.candidate { set_requires_verification }
      end

      @group = Group.new(visibility_level: Gitlab::CurrentSettings.default_group_visibility)
      @project = Project.new(namespace: @group)

      Gitlab::Tracking.event(self.class.name, 'view_new_group_action', user: current_user)
    end

    def create
      result = Registrations::StandardNamespaceCreateService.new(current_user, params).execute

      if result.success?
        finish_onboarding
        redirect_successful_namespace_creation(result.payload[:project].id)
      else
        @group = result.payload[:group]
        @project = result.payload[:project]

        render :new
      end
    end

    def import
      result = Registrations::ImportNamespaceCreateService.new(current_user, params).execute

      if result.success?
        finish_onboarding
        import_url = URI.join(root_url, params[:import_url], "?namespace_id=#{result.payload[:group].id}").to_s
        redirect_to import_url
      else
        @group = result.payload[:group]
        @project = result.payload[:project]

        render :new
      end
    end

    def exit
      return not_found unless Feature.enabled?(:exit_registration_verification)

      if current_user.requires_credit_card_verification
        ::Users::UpdateService.new(current_user, user: current_user, requires_credit_card_verification: false).execute!
      end

      finish_onboarding
      redirect_to root_url
    end

    private

    def authorize_create_group!
      access_denied! unless can?(current_user, :create_group)
    end

    def redirect_successful_namespace_creation(project_id)
      redirect_path = continuous_onboarding_getting_started_users_sign_up_welcome_path(
        project_id: project_id,
        trial_onboarding_flow: params[:trial_onboarding_flow]
      )

      experiment(:registration_verification, user: current_user) do |e|
        e.control { redirect_to redirect_path }
        e.candidate do
          store_location_for(:user, redirect_path)
          redirect_to new_users_sign_up_verification_path(project_id: project_id)
        end
      end
    end
  end
end

Registrations::GroupsProjectsController.prepend_mod
