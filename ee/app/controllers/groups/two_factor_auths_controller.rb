# frozen_string_literal: true
module Groups
  class TwoFactorAuthsController < Groups::ApplicationController
    before_action :authorize_admin_group!
    before_action :check_for_feature_flag
    before_action :set_user

    before_action do
      push_frontend_feature_flag(:group_owners_to_disable_two_factor)
    end

    feature_category :authentication_and_authorization

    def destroy
      result = TwoFactor::DestroyService.new(current_user, user: @user, group: group).execute

      if result[:status] == :success
        redirect_to(
          group_group_members_path(group),
          status: :found,
          notice: format(
            format(_("Two-factor authentication has been disabled successfully for %{username}!"),
                    username: @user.username)
          ))
      else
        redirect_to group_group_members_path(group), status: :found, alert: result[:message]
      end
    end

    private

    def set_user
      @user = User.find(params[:user_id])
    end

    def check_for_feature_flag
      render_404 unless Feature.enabled?('group_owners_to_disable_two_factor', group)
    end
  end
end
