# frozen_string_literal: true

module GitlabSubscriptions
  class CreateLeadService
    def execute(company_params)
      response = client.generate_trial(company_params)

      if response[:success]
        ServiceResponse.success
      else
        ServiceResponse.error(message: response.dig(:data, :errors))
      end
    end

    private

    def client
      Gitlab::SubscriptionPortal::Client
    end
  end
end
