# frozen_string_literal: true

module Onboarding
  class CreateIterableTriggerService
    def execute(params)
      response = client.generate_iterable(params)

      if response[:success]
        ServiceResponse.success
      else
        error_message = response.dig(:data, :errors) || 'Submission failed'
        ServiceResponse.error(message: error_message, reason: :submission_failed)
      end
    end

    private

    def client
      Gitlab::SubscriptionPortal::Client
    end
  end
end
