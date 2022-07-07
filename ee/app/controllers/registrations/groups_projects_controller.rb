# frozen_string_literal: true

module Registrations
  class GroupsProjectsController < ApplicationController
    include Registrations::CreateProject
    include Registrations::CreateGroup
    include Registrations::ApplyTrial
    include OneTrustCSP
    include GoogleAnalyticsCSP

    skip_before_action :require_verification, only: :new
    before_action :set_requires_verification, only: :new, if: -> { helpers.require_verification_experiment.candidate? }
    before_action :require_verification, only: [:create, :import], if: -> { current_user.requires_credit_card_verification }
    before_action only: [:new] do
      push_frontend_feature_flag(:gitlab_gtm_datalayer, type: :ops)
    end

    layout 'minimal'

    feature_category :onboarding

    def new
      helpers.require_verification_experiment.publish_to_database

      @group = Group.new(visibility_level: helpers.default_group_visibility)
      @project = Project.new(namespace: @group)

      combined_registration_experiment.track(:view_new_group_action)
    end

    def create
      @group = if group_id = params[:group][:id]
                 Group.find_by_id(group_id)
               else
                 Groups::CreateService.new(current_user, modified_group_params).execute
               end

      if @group.persisted?
        if @group.previously_new_record?
          combined_registration_experiment.track(:create_group, namespace: @group)
          helpers.require_verification_experiment.record_conversion(@group)

          unless apply_trial_when_in_trial_flow
            @project = Project.new(project_params) # #new requires a Project
            return render :new
          end
        end

        @project = ::Projects::CreateService.new(current_user, create_project_params).execute
        if @project.saved?
          combined_registration_experiment.track(:create_project, namespace: @project.namespace)

          create_learn_gitlab_project

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
      else
        @project = Project.new(project_params) # #new requires a Project
        render :new
      end
    end

    def import
      @group = Groups::CreateService.new(current_user, modified_group_params).execute
      if @group.persisted? && apply_trial_when_in_trial_flow
        combined_registration_experiment.track(:create_group, namespace: @group)
        helpers.require_verification_experiment.record_conversion(@group)

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

    def combined_registration_experiment
      @combined_registration_experiment ||= experiment(:combined_registration, user: current_user)
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

    def offer_trial?
      current_user.setup_for_company && !helpers.in_trial_onboarding_flow? && !params[:skip_trial].present?
    end

    def apply_trial_when_in_trial_flow
      !helpers.in_trial_onboarding_flow? || apply_trial
    end
  end
end
