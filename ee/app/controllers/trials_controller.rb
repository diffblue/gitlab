# frozen_string_literal: true

# EE:SaaS
# TODO: namespace https://gitlab.com/gitlab-org/gitlab/-/issues/338394
class TrialsController < ApplicationController
  include ActionView::Helpers::SanitizeHelper
  include OneTrustCSP
  include GoogleAnalyticsCSP
  include RegistrationsTracking

  layout 'minimal'

  skip_before_action :set_confirm_warning
  before_action :check_if_gl_com_or_dev
  before_action :authenticate_user!
  before_action only: [:new, :select] do
    push_frontend_feature_flag(:gitlab_gtm_datalayer, type: :ops)
  end

  feature_category :purchase
  urgency :low

  def new; end

  def select; end

  def create_lead
    lead_result = GitlabSubscriptions::CreateLeadService.new.execute({ trial_user: company_params })

    if lead_result.success?
      namespace = helpers.only_trialable_group_namespace
      if namespace.present? # only 1 possible namespace to apply trial, so we'll just automatically apply it
        params[:namespace_id] = namespace.id

        trial_result = GitlabSubscriptions::Trials::ApplyTrialService.new(**apply_trial_params).execute

        if trial_result.success?
          Gitlab::Tracking.event(self.class.name, 'create_trial', namespace: namespace, user: current_user)

          redirect_to trial_success_path(namespace)
        else
          # We couldn't apply the trial, so we'll bounce the user to the select form with errors
          # and give them option to create a group or try to re-apply the trial on the 1 namespace
          # in the select dropdown.
          @create_errors = trial_result.errors

          render :select
        end
      else # more than 1 possible namespace for trial, so we'll ask user and then apply trial
        redirect_to select_trials_path(glm_tracking_params)
      end
    else
      @create_errors = lead_result.errors

      render :new
    end
  end

  def apply
    # We only get to this action after the `create_lead` action has at least been tried, so the lead is captured
    # already.
    namespace =
      if find_namespace?
        current_user.namespaces.find_by_id(params[:namespace_id])
      elsif can_create_group?
        name = sanitize(params[:new_group_name])
        path = Namespace.clean_path(name.parameterize)
        Groups::CreateService.new(current_user, name: name, path: path).execute
      end

    return render_404 unless namespace.present?

    if namespace.persisted? # we possibly create a new namespace when we apply the trial due to `select` template form
      # namespace_id already set if namespace is found, resetting will not hurt and will lend to predictably always
      # setting as an integer instead of string sometimes and integer other times.
      params[:namespace_id] = namespace.id
      # test the indifferent access here...
      result = GitlabSubscriptions::Trials::ApplyTrialService.new(**apply_trial_params).execute

      if result.success?
        Gitlab::Tracking.event(self.class.name, 'create_trial', namespace: namespace, user: current_user)

        redirect_to trial_success_path(namespace)
      else
        # We couldn't apply the trial, so we'll bounce the user to the select form with errors
        # and give them the option to create a group or try to re-apply the trial on a namespace.
        # This assumes that the lead was already captured on initial try of `create_lead`.
        @create_errors = result.errors

        render :select
      end
    else
      # We didn't successfully create the group, so we get dumped here with form errors.
      @create_errors = namespace.errors.full_messages.to_sentence

      render :select
    end
  end

  private

  def trial_success_path(namespace)
    if discover_group_security_flow?
      group_security_dashboard_path(namespace, { trial: true })
    else
      stored_location_or_provided_path(group_path(namespace, { trial: true }))
    end
  end

  def stored_location_or_provided_path(path)
    if current_user.setup_for_company
      stored_location_for(:user) || path
    else
      path
    end
  end

  def authenticate_user!
    return if current_user

    redirect_to new_trial_registration_path(glm_tracking_params), alert: I18n.t('devise.failure.unauthenticated')
  end

  def company_params
    lead_params.merge(extra_params)
  end

  def lead_params
    params.permit(
      :company_name, :company_size, :first_name, :last_name, :phone_number,
      :country, :state, :website_url, :glm_content, :glm_source
    ).to_h
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

  def trial_params
    params.permit(:namespace_id, :trial_entity, :glm_source, :glm_content).to_h
  end

  def apply_trial_params
    gl_com_params = { gitlab_com_trial: true, sync_to_gl: true }

    {
      trial_user_information: trial_params.merge(gl_com_params),
      uid: current_user.id
    }
  end

  def find_namespace?
    params[:namespace_id].present? && params[:namespace_id] != '0'
  end

  def can_create_group?
    # Instance admins can disable user's ability to create top level groups.
    # See https://docs.gitlab.com/ee/user/admin_area/index.html#prevent-a-user-from-creating-groups
    params[:new_group_name].present? && can?(current_user, :create_group)
  end

  def discover_group_security_flow?
    %w[discover-group-security discover-project-security].include?(params[:glm_content])
  end
end

TrialsController.prepend_mod
