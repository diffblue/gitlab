# frozen_string_literal: true

module Registrations
  class GroupsProjectsController < ApplicationController
    include OneTrustCSP
    include GoogleAnalyticsCSP
    include Onboarding::SetRedirect

    skip_before_action :set_confirm_warning
    before_action :check_if_gl_com_or_dev
    before_action :authorize_create_group!, only: :new
    before_action only: [:new] do
      push_frontend_feature_flag(:gitlab_gtm_datalayer, type: :ops)
    end

    layout 'minimal'

    feature_category :onboarding

    urgency :low, [:create, :import]

    def new
      @group = Group.new(visibility_level: Gitlab::CurrentSettings.default_group_visibility)
      @project = Project.new(namespace: @group)

      track_event('view_new_group_action')
    end

    def create
      result = Registrations::StandardNamespaceCreateService.new(current_user, params).execute

      if result.success?
        track_event('successfully_submitted_form')
        finish_onboarding
        redirect_successful_namespace_creation(result.payload[:project])
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

    private

    def authorize_create_group!
      access_denied! unless can?(current_user, :create_group)
    end

    def redirect_successful_namespace_creation(project)
      redirect_path = onboarding_project_learn_gitlab_path(project,
        trial_onboarding_flow: params[:trial_onboarding_flow]
      )

      experiment(:registration_verification, user: current_user) do |e|
        e.control { redirect_to redirect_path }
        e.candidate do
          store_location_for(:user, redirect_path)
          redirect_to new_users_sign_up_verification_path(project_id: project.id)
        end
      end
    end

    def track_event(action)
      ::Gitlab::Tracking.event(self.class.name, action, user: current_user, label: helpers.onboarding_track_label)
    end
  end
end

Registrations::GroupsProjectsController.prepend_mod
