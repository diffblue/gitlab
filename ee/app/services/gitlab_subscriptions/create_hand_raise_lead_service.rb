# frozen_string_literal: true

module GitlabSubscriptions
  class CreateHandRaiseLeadService
    def execute(params)
      response = client.generate_lead(hardcoded_values.merge(params))

      if response[:success]
        ServiceResponse.success
      else
        ServiceResponse.error(message: response.dig(:data, :errors))
      end
    end

    private

    def hardcoded_values
      {
        product_interaction: 'Hand Raise PQL'
      }
    end

    def client
      Gitlab::SubscriptionPortal::Client
    end
  end
end
