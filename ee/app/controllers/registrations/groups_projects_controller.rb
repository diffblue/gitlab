# frozen_string_literal: true

module Registrations
  class GroupsProjectsController < ApplicationController
    include LearnGitlabHelper
    include OneTrustCSP
    include GoogleAnalyticsCSP

    skip_before_action :require_verification, only: :new
    skip_before_action :set_confirm_warning
    before_action :check_if_gl_com_or_dev
    before_action :authorize_create_group!, only: :new
    before_action :set_requires_verification, only: :new, if: -> { helpers.require_verification_experiment.candidate? }
    before_action :require_verification,
                  only: [:create, :import],
                  if: -> { current_user.requires_credit_card_verification }
    before_action only: [:new] do
      push_frontend_feature_flag(:gitlab_gtm_datalayer, type: :ops)
    end

    layout 'minimal'

    feature_category :onboarding

    def new
      helpers.require_verification_experiment.publish_to_database

      @group = Group.new(visibility_level: helpers.default_group_visibility)
      @project = Project.new(namespace: @group)

      Gitlab::Tracking.event(self.class.name, 'view_new_group_action', user: current_user)
    end

    def create
      group_id = params[:group][:id]

      if group_id # sad path: partial failure scenario where group was created, but project wasn't
        @group = Group.find_by_id(group_id)

        create_project_flow
      else
        # happy path: first time submit
        @group = Groups::CreateService.new(current_user, modified_group_params).execute

        create_with_new_group_flow
      end
    end

    def import
      @group = Groups::CreateService.new(current_user, modified_group_params).execute

      if @group.persisted?
        Gitlab::Tracking.event(self.class.name, 'create_group_import', namespace: @group, user: current_user)
        helpers.require_verification_experiment.record_conversion(@group)

        apply_trial if helpers.in_trial_onboarding_flow?

        import_url = URI.join(root_url, params[:import_url], "?namespace_id=#{@group.id}").to_s
        redirect_to import_url
      else
        @project = Project.new(namespace: @group) # #new requires a Project

        render :new
      end
    end

    def exit
      return not_found unless Feature.enabled?(:exit_registration_verification)

      if current_user.requires_credit_card_verification
        ::Users::UpdateService.new(current_user, user: current_user, requires_credit_card_verification: false).execute!
      end

      redirect_to root_url
    end

    private

    def create_with_new_group_flow
      if @group.persisted?
        Gitlab::Tracking.event(self.class.name, 'create_group', namespace: @group, user: current_user)
        helpers.require_verification_experiment.record_conversion(@group)

        apply_trial if helpers.in_trial_onboarding_flow?

        create_project_flow
      else
        @project = Project.new(project_params) # #new requires a Project

        render :new
      end
    end

    def create_project_flow
      @project = ::Projects::CreateService.new(current_user, create_project_params).execute

      if @project.persisted?
        Gitlab::Tracking.event(self.class.name, 'create_project', namespace: @project.namespace, user: current_user)

        create_learn_gitlab_project(@project.namespace_id)

        redirect_path = continuous_onboarding_getting_started_users_sign_up_welcome_path(project_id: @project.id)

        if helpers.registration_verification_enabled?
          store_location_for(:user, redirect_path)
          redirect_to new_users_sign_up_verification_path(project_id: @project.id, offer_trial: offer_trial?)
        elsif offer_trial?
          store_location_for(:user, redirect_path)
          redirect_to new_trial_path
        else
          redirect_to redirect_path
        end
      else
        render :new
      end
    end

    def authorize_create_group!
      access_denied! unless can?(current_user, :create_group)
    end

    def create_project_params
      project_params(:initialize_with_readme)
    end

    def project_params(*extra)
      params.require(:project).permit(project_params_attributes + extra).merge(namespace_id: @group.id)
    end

    def modified_group_params
      group_name = params.dig(:group, :name)
      modifed_group_params = group_params
      if group_name.present? && params.dig(:group, :path).blank?
        modifed_group_params = modifed_group_params.compact_blank.with_defaults(path: Namespace.clean_path(group_name))
      end

      modifed_group_params
    end

    def group_params
      params.require(:group).permit(
        :name,
        :path,
        :visibility_level
      ).merge(
        create_event: true,
        setup_for_company: current_user.setup_for_company
      )
    end

    def offer_trial?
      current_user.setup_for_company && !helpers.in_trial_onboarding_flow? && !params[:skip_trial].present?
    end

    def apply_trial
      trial_user_information = params.permit(:glm_source, :glm_content).merge({
                                                                                namespace_id: @group.id,
                                                                                gitlab_com_trial: true,
                                                                                sync_to_gl: true
                                                                              })

      if Feature.enabled?(:registration_trial_in_background)
        GitlabSubscriptions::Trials::ApplyTrialWorker.perform_async(current_user.id, trial_user_information) # rubocop:todo CodeReuse/Worker
      else
        apply_trial_params = {
          uid: current_user.id,
          trial_user: trial_user_information
        }

        result = GitlabSubscriptions::ApplyTrialService.new.execute(apply_trial_params)
        trial_errors = result&.dig(:errors)

        Gitlab::AppLogger.error "Failed to apply a trial with #{trial_errors}" if trial_errors.present?
      end
    end

    LEARN_GITLAB_ULTIMATE_TEMPLATE = 'learn_gitlab_ultimate.tar.gz'

    def learn_gitlab_template_path
      Rails.root.join('vendor', 'project_templates', LEARN_GITLAB_ULTIMATE_TEMPLATE)
    end

    def create_learn_gitlab_project(parent_project_namespace_id)
      ::Onboarding::CreateLearnGitlabWorker.perform_async(learn_gitlab_template_path, # rubocop:todo CodeReuse/Worker
                                                          learn_gitlab_project_name,
                                                          parent_project_namespace_id,
                                                          current_user.id)
    end

    def learn_gitlab_project_name
      if helpers.in_trial_onboarding_flow?
        Onboarding::LearnGitlab::PROJECT_NAME_ULTIMATE_TRIAL
      else
        Onboarding::LearnGitlab::PROJECT_NAME
      end
    end

    def project_params_attributes
      [
        :namespace_id,
        :name,
        :path,
        :visibility_level
      ]
    end
  end
end

Registrations::GroupsProjectsController.prepend_mod
