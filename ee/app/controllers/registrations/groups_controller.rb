# frozen_string_literal: true

module Registrations
  class GroupsController < ApplicationController
    include Registrations::CreateGroup
    include Registrations::ApplyTrial
    include ::Gitlab::Utils::StrongMemoize
    include OneTrustCSP
    include GoogleAnalyticsCSP

    layout 'minimal'

    feature_category :onboarding

    def new
      @group = Group.new(visibility_level: helpers.default_group_visibility)
      experiment(:combined_registration, user: current_user).track(:view_new_group_action)
      push_frontend_feature_flag(:gitlab_gtm_datalayer, type: :ops)
    end

    def create
      @group = Groups::CreateService.new(current_user, group_params).execute

      if @group.persisted?
        experiment(:combined_registration, user: current_user).track(:create_group, namespace: @group)

        create_successful_flow
      else
        render action: :new
      end
    end

    private

    def create_successful_flow
      if helpers.in_trial_onboarding_flow?
        apply_trial_for_trial_onboarding_flow
      else
        registration_onboarding_flow
      end
    end

    def apply_trial_for_trial_onboarding_flow
      if apply_trial
        redirect_to new_users_sign_up_project_path(namespace_id: @group.id, trial: helpers.in_trial_during_signup_flow?, trial_onboarding_flow: true)
      else
        render action: :new
      end
    end

    def registration_onboarding_flow
      if helpers.in_trial_during_signup_flow?
        create_lead_and_apply_trial_flow
      else
        redirect_to new_users_sign_up_project_path(namespace_id: @group.id, trial: false)
      end
    end

    def create_lead_and_apply_trial_flow
      if create_lead && apply_trial
        redirect_to new_users_sign_up_project_path(namespace_id: @group.id, trial: true)
      else
        render action: :new
      end
    end

    def create_lead
      trial_params = {
        trial_user: params.permit(
          :company_name,
          :company_size,
          :phone_number,
          :country
        ).merge(
          work_email: current_user.email,
          first_name: current_user.first_name,
          last_name: current_user.last_name,
          uid: current_user.id,
          setup_for_company: current_user.setup_for_company,
          skip_email_confirmation: true,
          gitlab_com_trial: true,
          provider: 'gitlab',
          newsletter_segment: current_user.email_opted_in
        )
      }
      result = GitlabSubscriptions::CreateLeadService.new.execute(trial_params)
      flash[:alert] = result&.dig(:errors) unless result&.dig(:success)

      result&.dig(:success)
    end
  end
end
