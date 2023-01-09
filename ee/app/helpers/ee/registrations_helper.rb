# frozen_string_literal: true

module EE
  module RegistrationsHelper
    include ::Gitlab::Utils::StrongMemoize

    def shuffled_registration_objective_options
      options = registration_objective_options
      other = options.extract!(:other).to_a.flatten
      options.to_a.shuffle.append(other).map { |option| option.reverse }
    end

    def registration_verification_data
      url = if params[:learn_gitlab_project_id].present?
              trial_getting_started_users_sign_up_welcome_path(params.slice(:learn_gitlab_project_id).permit!)
            elsif params[:project_id].present?
              continuous_onboarding_getting_started_users_sign_up_welcome_path(params.slice(:project_id).permit!)
            else
              root_path
            end

      { next_step_url: url }
    end

    def credit_card_verification_data
      {
        completed: current_user.credit_card_validation.present?.to_s,
        iframe_url: ::Gitlab::SubscriptionPortal::REGISTRATION_VALIDATION_FORM_URL,
        allowed_origin: ::Gitlab::SubscriptionPortal::SUBSCRIPTIONS_URL
      }
    end

    def arkose_labs_data
      return {} unless ::Feature.enabled?(:arkose_labs_signup_challenge)

      {
        api_key: Arkose::Settings.arkose_public_api_key,
        domain: Arkose::Settings.arkose_labs_domain
      }
    end

    private

    def redirect_path
      strong_memoize(:redirect_path) do
        # we use direct session here since stored_location_for
        # will delete the value upon fetching
        redirect_to = session['user_return_to']
        URI.parse(redirect_to).path if redirect_to
      end
    end

    def registration_objective_options
      localized_jobs_to_be_done_choices.dup
    end
  end
end
