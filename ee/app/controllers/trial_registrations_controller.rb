# frozen_string_literal: true

# EE:SaaS
# TODO: namespace https://gitlab.com/gitlab-org/gitlab/-/issues/338394
class TrialRegistrationsController < RegistrationsController
  extend ::Gitlab::Utils::Override

  include OneTrustCSP
  include BizibleCSP
  include GoogleAnalyticsCSP
  include GoogleSyndicationCSP

  layout 'minimal'

  skip_before_action :require_no_authentication_without_flash

  before_action :check_if_gl_com_or_dev
  before_action :redirect_to_trial, only: [:new], if: :user_signed_in?
  before_action only: [:new] do
    push_frontend_feature_flag(:gitlab_gtm_datalayer, type: :ops)
  end

  override :new
  def new
    @resource = Users::AuthorizedBuildService.new(nil, {}).execute
  end

  private

  def redirect_to_trial
    redirect_to new_trial_path(request.query_parameters)
  end

  override :after_sign_up_path
  def after_sign_up_path
    ::Gitlab::Utils.add_url_parameters(super, { trial: true })
  end

  override :sign_up_params_attributes
  def sign_up_params_attributes
    [:first_name, :last_name, :username, :email, :password]
  end

  override :resource
  def resource
    @resource ||= Users::AuthorizedBuildService.new(current_user, sign_up_params).execute
  end

  override :arkose_labs_enabled?
  def arkose_labs_enabled?
    super && Feature.enabled?(:arkose_labs_trial_signup_challenge)
  end
end

TrialRegistrationsController.prepend_mod
