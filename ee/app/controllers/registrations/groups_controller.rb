# frozen_string_literal: true

module Registrations
  class GroupsController < ApplicationController
    include OneTrustCSP
    include GoogleAnalyticsCSP
    include GoogleSyndicationCSP
    include ::Onboarding::SetRedirect

    skip_before_action :set_confirm_warning
    before_action :check_if_gl_com_or_dev
    before_action :authorize_create_group!, only: :new
    before_action only: [:new] do
      push_frontend_feature_flag(:gitlab_gtm_datalayer, type: :ops)
    end

    layout 'minimal'

    feature_category :onboarding

    urgency :low, [:create]

    def new
      @group = Group.new(visibility_level: Gitlab::CurrentSettings.default_group_visibility)
      @project = Project.new(namespace: @group)
      @initialize_with_readme = true

      track_event('view_new_group_action')
    end

    def create
      service_class = if import?
                        Registrations::ImportNamespaceCreateService
                      else
                        Registrations::StandardNamespaceCreateService
                      end

      result = service_class.new(current_user, params).execute

      if result.success?
        actions_after_success(result.payload)
      else
        @group = result.payload[:group]
        @project = result.payload[:project]
        @initialize_with_readme = params.dig(:project, :initialize_with_readme)

        render :new
      end
    end

    private

    def actions_after_success(payload)
      finish_onboarding(current_user)

      if import?
        import_url = URI.join(root_url, params[:import_url], "?namespace_id=#{payload[:group].id}").to_s
        redirect_to import_url
      else
        track_event('successfully_submitted_form')

        redirect_to onboarding_project_learn_gitlab_path(payload[:project],
          trial_onboarding_flow: params[:trial_onboarding_flow]
        )
      end
    end

    def authorize_create_group!
      access_denied! unless can?(current_user, :create_group)
    end

    def import?
      params[:import_url].present?
    end

    def track_event(action)
      ::Gitlab::Tracking
        .event(self.class.name, action, user: current_user, label: onboarding_status.group_creation_tracking_label)
    end

    def onboarding_status
      ::Onboarding::Status.new(params, session, current_user)
    end
    strong_memoize_attr :onboarding_status
  end
end
