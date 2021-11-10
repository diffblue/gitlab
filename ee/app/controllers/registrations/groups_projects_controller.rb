# frozen_string_literal: true

module Registrations
  class GroupsProjectsController < ApplicationController
    include Registrations::CreateProject
    include Registrations::CreateGroup

    layout 'minimal'

    feature_category :onboarding

    def new
      @group = Group.new(visibility_level: helpers.default_group_visibility)
      @project = Project.new(namespace: @group)

      combined_registration_experiment.track(:view_new_group_action)
      experiment(:trial_registration_with_reassurance, actor: current_user)
        .track(:render, label: 'registrations:groups:new', user: current_user)
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
        end

        @project = ::Projects::CreateService.new(current_user, project_params).execute
        if @project.saved?
          combined_registration_experiment.track(:create_project, namespace: @project.namespace)

          learn_gitlab_project = create_learn_gitlab_project

          if helpers.in_trial_onboarding_flow?
            record_experiment_user(:remove_known_trial_form_fields_welcoming, namespace_id: @group.id)
            record_experiment_conversion_event(:remove_known_trial_form_fields_welcoming)

            redirect_to trial_getting_started_users_sign_up_welcome_path(learn_gitlab_project_id: learn_gitlab_project.id)
          else
            success_url = continuous_onboarding_getting_started_users_sign_up_welcome_path(project_id: @project.id)

            if current_user.setup_for_company
              store_location_for(:user, success_url)
              success_url = new_trial_path
            end

            redirect_to success_url
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
      if @group.persisted?
        combined_registration_experiment.track(:create_group, namespace: @group)

        import_url = URI.join(root_url, params[:import_url], "?namespace_id=#{@group.id}").to_s
        redirect_to import_url
      else
        @project = Project.new(namespace: @group) # #new requires a Project
        render :new
      end
    end

    private

    def combined_registration_experiment
      @combined_registration_experiment ||= experiment(:combined_registration, user: current_user)
    end

    def project_params
      params.require(:project).permit(project_params_attributes).merge(namespace_id: @group.id)
    end

    def modified_group_params
      group_name = params.dig(:group, :name)
      modifed_group_params = group_params
      if group_name.present? && params.dig(:group, :path).blank?
        modifed_group_params = modifed_group_params.compact_blank.with_defaults(path: Namespace.clean_path(group_name))
      end

      modifed_group_params.merge(create_event: true)
    end
  end
end
