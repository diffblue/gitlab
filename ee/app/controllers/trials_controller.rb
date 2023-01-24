# frozen_string_literal: true

# EE:SaaS
# TODO: namespace https://gitlab.com/gitlab-org/gitlab/-/issues/338394
class TrialsController < ApplicationController
  include ActionView::Helpers::SanitizeHelper
  include OneTrustCSP
  include GoogleAnalyticsCSP
  include RegistrationsTracking

  layout 'minimal'

  before_action :check_if_gl_com_or_dev
  before_action :authenticate_user!, except: [:create_hand_raise_lead]
  before_action :authenticate_user_404!, only: [:create_hand_raise_lead]
  before_action :find_or_create_namespace, only: :apply
  before_action :find_namespace, only: [:extend_reactivate, :create_hand_raise_lead]
  before_action :authenticate_namespace_owner!, only: [:extend_reactivate]
  before_action only: [:new, :select] do
    push_frontend_feature_flag(:gitlab_gtm_datalayer, type: :ops)
  end

  feature_category :purchase
  urgency :low

  def new
  end

  def select
  end

  def create_lead
    @result = GitlabSubscriptions::CreateLeadService.new.execute({ trial_user: company_params })

    render(:new) && return unless @result.success?

    @namespace = helpers.only_trialable_group_namespace

    if @namespace.present?
      params[:namespace_id] = @namespace.id
      apply_trial_and_redirect
    else
      redirect_to select_trials_path(glm_tracking_params)
    end
  end

  def create_hand_raise_lead
    result = GitlabSubscriptions::CreateHandRaiseLeadService.new.execute(hand_raise_lead_params)

    if result.success?
      head :ok
    else
      render_403
    end
  end

  def apply
    apply_trial_and_redirect
  end

  def extend_reactivate
    render_404 unless Feature.enabled?(:allow_extend_reactivate_trial)

    result = GitlabSubscriptions::ExtendReactivateTrialService.new.execute(extend_reactivate_trial_params) if valid_extension?

    if result&.success?
      head :ok
    else
      render_403
    end
  end

  def skip
    redirect_to stored_location_or_provided_path(dashboard_projects_path)
  end

  protected

  # override the ConfirmEmailWarning method in order to skip
  def show_confirm_warning?
    false
  end

  private

  def stored_location_or_provided_path(path)
    if current_user.setup_for_company
      stored_location_for(:user) || path
    else
      path
    end
  end

  def authenticate_user!
    return if current_user

    redirect_to new_trial_registration_path, alert: I18n.t('devise.failure.unauthenticated')
  end

  def authenticate_user_404!
    render_404 unless current_user
  end

  def authenticate_namespace_owner!
    user_is_namespace_owner = if @namespace.is_a?(Group)
                                @namespace.owners.include?(current_user)
                              else
                                @namespace.owner == current_user
                              end

    render_403 unless user_is_namespace_owner
  end

  def hand_raise_lead_params
    params.permit(:first_name, :last_name, :company_name, :company_size, :phone_number, :country,
                  :state, :namespace_id, :comment, :glm_content)
          .merge(hand_raise_lead_extra_params)
  end

  def hand_raise_lead_extra_params
    {
      work_email: current_user.email,
      uid: current_user.id,
      provider: 'gitlab',
      setup_for_company: current_user.setup_for_company,
      glm_source: 'gitlab.com'
    }
  end

  def company_params
    params.permit(:company_name, :company_size, :first_name, :last_name, :phone_number,
                  :country, :state, :website_url, :glm_content, :glm_source).merge(extra_params)
  end

  def extra_params
    attrs = {}
    attrs[:work_email] = current_user.email
    attrs[:uid] = current_user.id
    attrs[:setup_for_company] = current_user.setup_for_company
    attrs[:skip_email_confirmation] = true
    attrs[:gitlab_com_trial] = true
    attrs[:provider] = 'gitlab'
    attrs[:newsletter_segment] = current_user.email_opted_in

    attrs
  end

  def apply_trial_params
    gl_com_params = { gitlab_com_trial: true, sync_to_gl: true }

    {
      trial_user_information: params.permit(:namespace_id, :trial_entity, :glm_source, :glm_content).merge(gl_com_params),
      uid: current_user.id
    }
  end

  def extend_reactivate_trial_params
    gl_com_params = { gitlab_com_trial: true }

    {
      trial_user: params.permit(:namespace_id, :trial_extension_type, :trial_entity, :glm_source, :glm_content).merge(gl_com_params),
      uid: current_user.id
    }
  end

  def find_or_create_namespace
    @namespace = if find_namespace?
                   current_user.namespaces.find_by_id(params[:namespace_id])
                 elsif can_create_group?
                   create_group
                 end

    render_404 unless @namespace
  end

  def find_namespace
    @namespace = if find_namespace?
                   current_user.namespaces.find_by_id(params[:namespace_id])
                 end

    render_404 unless @namespace
  end

  def find_namespace?
    params[:namespace_id].present? && params[:namespace_id] != '0'
  end

  def valid_extension?
    trial_extension_type = params[:trial_extension_type].to_i

    return false unless GitlabSubscription.trial_extension_types.value?(trial_extension_type)

    return false if trial_extension_type == GitlabSubscription.trial_extension_types[:extended] && !@namespace.can_extend_trial?

    return false if trial_extension_type == GitlabSubscription.trial_extension_types[:reactivated] && !@namespace.can_reactivate_trial?

    true
  end

  def can_create_group?
    params[:new_group_name].present? && can?(current_user, :create_group)
  end

  def create_group
    name = sanitize(params[:new_group_name])
    group = Groups::CreateService.new(current_user, name: name, path: Namespace.clean_path(name.parameterize)).execute

    params[:namespace_id] = group.id if group.persisted?

    group
  end

  def discover_group_security_flow?
    %w(discover-group-security discover-project-security).include?(params[:glm_content])
  end

  def apply_trial_and_redirect
    return render(:select) if @namespace.invalid?

    @result = GitlabSubscriptions::Trials::ApplyTrialService.new(**apply_trial_params).execute

    if @result.success?
      Gitlab::Tracking.event(self.class.name, 'create_trial', namespace: @namespace, user: current_user)

      if discover_group_security_flow?
        redirect_to group_security_dashboard_url(@namespace, { trial: true })
      else
        redirect_to stored_location_or_provided_path(group_url(@namespace, { trial: true }))
      end
    else
      render :select
    end
  end
end
