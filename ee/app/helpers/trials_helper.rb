# frozen_string_literal: true

module TrialsHelper
  TRIAL_ONBOARDING_SOURCE_URLS = %w[about.gitlab.com docs.gitlab.com learn.gitlab.com].freeze

  def create_lead_form_data
    {
      submit_path: create_lead_trials_path(glm_params),
      first_name: current_user.first_name,
      last_name: current_user.last_name,
      company_name: current_user.organization
    }.merge(
      params.slice(
        :first_name, :last_name, :company_name, :company_size, :phone_number, :country, :state
      ).to_unsafe_h.symbolize_keys
    )
  end

  def create_company_form_data
    submit_params = glm_params.merge(passed_through_params.to_unsafe_h.symbolize_keys)
    {
      submit_path: users_sign_up_company_path(submit_params)
    }
  end

  def should_ask_company_question?
    TRIAL_ONBOARDING_SOURCE_URLS.exclude?(glm_params[:glm_source])
  end

  def glm_params
    strong_memoize(:glm_params) do
      params.slice(:glm_source, :glm_content).to_unsafe_h
    end
  end

  def glm_source
    ::Gitlab.config.gitlab.host
  end

  def trial_selection_intro_text
    if any_trialable_group_namespaces?
      s_('Trials|You can apply your trial to a new group or an existing group.')
    else
      s_('Trials|Create a new group to start your GitLab Ultimate trial.')
    end
  end

  def show_trial_namespace_select?
    any_trialable_group_namespaces?
  end

  def namespace_options_for_listbox
    group_options = trialable_group_namespaces.map { |n| { text: n.name, value: n.id.to_s } }
    options = [
      {
        text: _('New'),
        options: [
          {
            text: _('Create group'),
            value: '0'
          }
        ]
      }
    ]

    options.push(text: _('Groups'), options: group_options) unless group_options.empty?

    options
  end

  def trial_errors(namespace, service_result)
    # when select action is hit directly(not via render),
    # service_result/namespace will be nil due to @result being nil
    namespace&.errors&.full_messages&.to_sentence&.presence || service_result&.errors&.presence
  end

  def only_trialable_group_namespace
    trialable_group_namespaces.first if trialable_group_namespaces.count == 1
  end

  private

  def passed_through_params
    params.slice(
      :trial,
      :role,
      :registration_objective,
      :jobs_to_be_done_other
    )
  end

  def trialable_group_namespaces
    strong_memoize(:trialable_group_namespaces) do
      current_user.manageable_groups_eligible_for_trial
    end
  end

  def any_trialable_group_namespaces?
    trialable_group_namespaces.any?
  end
end
