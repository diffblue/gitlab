# frozen_string_literal: true

module Registrations
  class GroupInvitesController < Groups::ApplicationController
    layout 'checkout'

    before_action :check_if_gl_com_or_dev
    before_action :authorize_invite_to_group!

    feature_category :navigation

    def new
    end

    def create
      Members::CreateService.new(current_user, invite_params).execute

      experiment(:force_company_trial, user: current_user).track(:create_invite, namespace: group, user: current_user)

      redirect_to new_users_sign_up_project_path(namespace_id: group.id,
                                                 trial: helpers.in_trial_during_signup_flow?,
                                                 trial_onboarding_flow: helpers.in_trial_onboarding_flow?,
                                                 hide_trial_activation_banner: true)
    end

    private

    def authorize_invite_to_group!
      access_denied! unless can?(current_user, :admin_group_member, group)
    end

    def group
      @group ||= Group.find(params[:group_id])
    end

    def invite_params
      {
        source: group,
        user_ids: emails_param[:emails]&.reject(&:blank?)&.join(','),
        access_level: Gitlab::Access::DEVELOPER,
        invite_source: 'registrations-group-invite'
      }
    end

    def emails_param
      params.permit(emails: [])
    end
  end
end
