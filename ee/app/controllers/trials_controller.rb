# frozen_string_literal: true

class TrialsController < ApplicationController
  include ActionView::Helpers::SanitizeHelper

  layout 'minimal'

  before_action :check_if_gl_com_or_dev
  before_action :authenticate_user!
  before_action :find_or_create_namespace, only: :apply
  before_action :find_namespace, only: [:extend_reactivate]
  before_action :authenticate_namespace_owner!, only: [:extend_reactivate]

  feature_category :purchase

  def new
    record_experiment_user(:remove_known_trial_form_fields, remove_known_trial_form_fields_context)
  end

  def select
  end

  def create_lead
    url_params = { glm_source: params[:glm_source], glm_content: params[:glm_content] }
    @result = GitlabSubscriptions::CreateLeadService.new.execute({ trial_user: company_params })

    render(:new) && return unless @result[:success]

    if params[:glm_source] == 'about.gitlab.com'
      record_experiment_user(:trial_onboarding_issues)
      return redirect_to(new_users_sign_up_group_path(url_params.merge(trial_onboarding_flow: true))) if experiment_enabled?(:trial_onboarding_issues)
    end

    redirect_to select_trials_url(url_params)
  end

  def apply
    return render(:select) if @namespace.invalid?

    @result = GitlabSubscriptions::ApplyTrialService.new.execute(apply_trial_params)

    if @result&.dig(:success)
      record_experiment_user(:remove_known_trial_form_fields, namespace_id: @namespace.id)
      record_experiment_user(:trial_onboarding_issues, namespace_id: @namespace.id)
      record_experiment_conversion_event(:remove_known_trial_form_fields)
      record_experiment_conversion_event(:trial_onboarding_issues)

      if discover_group_security_flow?
        redirect_trial_user_to_feature_experiment_flow
      else
        redirect_to group_url(@namespace, { trial: true })
      end
    else
      render :select
    end
  end

  def extend_reactivate
    render_404 unless Feature.enabled?(:allow_extend_reactivate_trial)

    result = GitlabSubscriptions::ExtendReactivateTrialService.new.execute(extend_reactivate_trial_params) if valid_extension?

    if result&.success?
      head 200
    else
      render_403
    end
  end

  protected

  # override the ConfirmEmailWarning method in order to skip
  def show_confirm_warning?
    false
  end

  private

  def authenticate_user!
    return if current_user

    redirect_to new_trial_registration_path, alert: I18n.t('devise.failure.unauthenticated')
  end

  def authenticate_namespace_owner!
    user_is_namespace_owner = if @namespace.is_a?(Group)
                                @namespace.owners.include?(current_user)
                              else
                                @namespace.owner == current_user
                              end

    render_403 unless user_is_namespace_owner
  end

  def company_params
    params.permit(:company_name, :company_size, :first_name, :last_name, :phone_number, :number_of_users, :country)
          .merge(extra_params)
  end

  def extra_params
    attrs = {}
    attrs[:work_email] = current_user.email
    attrs[:uid] = current_user.id
    attrs[:skip_email_confirmation] = true
    attrs[:gitlab_com_trial] = true
    attrs[:provider] = 'gitlab'
    attrs[:newsletter_segment] = current_user.email_opted_in

    attrs
  end

  def apply_trial_params
    gl_com_params = { gitlab_com_trial: true, sync_to_gl: true }

    {
      trial_user: params.permit(:namespace_id, :trial_entity, :glm_source, :glm_content).merge(gl_com_params),
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

  def remove_known_trial_form_fields_context
    {
      first_name_present: current_user.first_name.present?,
      last_name_present: current_user.last_name.present?,
      company_name_present: current_user.organization.present?
    }
  end

  def redirect_trial_user_to_feature_experiment_flow
    experiment(:redirect_trial_user_to_feature, namespace: @namespace) do |e|
      e.record!
      e.use { redirect_to group_url(@namespace, { trial: true }) }
      e.try { redirect_to group_security_dashboard_url(@namespace, { trial: true }) }
    end
  end

  def discover_group_security_flow?
    params[:glm_content] == 'discover-group-security'
  end
end
