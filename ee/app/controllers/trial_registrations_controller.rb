# frozen_string_literal: true

# EE:SaaS
# TODO: namespace https://gitlab.com/gitlab-org/gitlab/-/issues/338394
class TrialRegistrationsController < RegistrationsController
  extend ::Gitlab::Utils::Override

  layout 'minimal'

  skip_before_action :require_no_authentication

  before_action :check_if_gl_com_or_dev
  before_action :set_redirect_url, only: [:new]

  def new
  end

  private

  def set_redirect_url
    target_url = new_trial_url(params: request.query_parameters)

    if user_signed_in?
      redirect_to target_url
    else
      store_location_for(:user, target_url)
    end
  end

  override :sign_up_params
  def sign_up_params
    if params[:user]
      params.require(:user).permit(:first_name, :last_name, :username, :email, :password, :skip_confirmation, :email_opted_in)
    else
      {}
    end
  end

  def resource
    @resource ||= Users::AuthorizedBuildService.new(current_user, sign_up_params).execute
  end
end
