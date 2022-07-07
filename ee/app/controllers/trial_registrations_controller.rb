# frozen_string_literal: true

# EE:SaaS
# TODO: namespace https://gitlab.com/gitlab-org/gitlab/-/issues/338394
class TrialRegistrationsController < RegistrationsController
  include OneTrustCSP
  include BizibleCSP
  include GoogleAnalyticsCSP

  layout 'minimal'

  skip_before_action :require_no_authentication

  before_action :check_if_gl_com_or_dev
  before_action :set_redirect_url, only: [:new]
  before_action :add_onboarding_parameter_to_redirect_url, only: :create
  before_action only: [:new] do
    push_frontend_feature_flag(:gitlab_gtm_datalayer, type: :ops)
  end

  def new
  end

  private

  def set_redirect_url
    target_url =
      if ::Feature.enabled?(:about_your_company_registration_flow)
        new_users_sign_up_company_path(trial: true)
      else
        new_trial_url(params: request.query_parameters)
      end

    if user_signed_in?
      redirect_to target_url
    else
      store_location_for(:user, target_url)
    end
  end

  def add_onboarding_parameter_to_redirect_url
    stored_url = stored_location_for(:user)
    return unless stored_url.present?

    redirect_uri = Gitlab::Utils.add_url_parameters(stored_url, onboarding: true)
    store_location_for(:user, redirect_uri)
  end

  def sign_up_params
    if params[:user]
      params.require(:user).permit(*sign_up_params_attributes)
    else
      {}
    end
  end

  def sign_up_params_attributes
    [:first_name, :last_name, :username, :email, :password, :skip_confirmation, :email_opted_in]
  end

  def resource
    @resource ||= Users::AuthorizedBuildService.new(current_user, sign_up_params).execute
  end
end

TrialRegistrationsController.prepend_mod
