# frozen_string_literal: true

module GitlabSubscriptions
  class CreateHandRaiseLeadService
    def execute(params)
      response = client.generate_lead(params)

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
