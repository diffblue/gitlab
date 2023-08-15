# frozen_string_literal: true

module GitlabSubscriptions
  class CreateTrialOrLeadService
    def initialize(user:, params:)
      @onboarding_status = ::Onboarding::Status.new(params, nil, nil)

      merged_params = params.merge(hardcoded_values).merge(user_values(user))
      @params = remapping_for_api(merged_params)
    end

    def execute
      response = submit_client_request

      if response[:success]
        ServiceResponse.success
      else
        error_message = response.dig(:data, :errors) || 'Submission failed'
        ServiceResponse.error(message: error_message, reason: :submission_failed)
      end
    end

    private

    def hardcoded_values
      {
        provider: 'gitlab',
        skip_email_confirmation: true,
        gitlab_com_trial: true
      }
    end

    def user_values(user)
      {
        uid: user.id,
        work_email: user.email,
        setup_for_company: user.setup_for_company,
        newsletter_segment: user.email_opted_in
      }
    end

    def remapping_for_api(params)
      params[:jtbd] = params.delete(:registration_objective)
      params[:comment] ||= params.delete(:jobs_to_be_done_other)
      params
    end

    def submit_client_request
      if @onboarding_status.trial_onboarding_flow?
        client.generate_trial(
          @params.merge(product_interaction: ::Onboarding::Status::PRODUCT_INTERACTION[:trial])
        )
      else
        client.generate_lead(
          @params.except(:glm_source, :glm_content)
                 .merge(product_interaction: ::Onboarding::Status::PRODUCT_INTERACTION[:lead])
        )
      end
    end

    def client
      Gitlab::SubscriptionPortal::Client
    end
  end
end
