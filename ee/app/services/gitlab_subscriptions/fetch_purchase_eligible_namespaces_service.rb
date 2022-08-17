# frozen_string_literal: true

# Fetch a list of namespaces and filter them by their eligibility to purchase a new subscription
#
# - When `plan_id: ID` is supplied the eligibility will be checked for that specific plan ID.
#   This param should be supplied when checking add on pack eligibility.
# - When `any_self_service_plan: Boolean` is supplied, the eligibility to have a new self-service plan
#   (ie Premium/Ultimate) in general is checked.
# - When present, the account id associated with the namespace will be added.
#   This is needed in the context of add on purchase, in order to correctly initialise the payment form.
module GitlabSubscriptions
  class FetchPurchaseEligibleNamespacesService
    include ::Gitlab::Utils::StrongMemoize

    def initialize(user:, namespaces:, plan_id: nil, any_self_service_plan: nil)
      @user = user
      @namespaces = namespaces
      @plan_id = plan_id
      @any_self_service_plan = any_self_service_plan
    end

    def execute
      return success([]) if namespaces.empty?
      return missing_user_error if user.nil?
      return missing_plan_error if plan_id.nil? && any_self_service_plan.nil?

      if response[:success] && response[:data]
        eligible_namespaces = response[:data].to_h { |data| [data["id"], [data["accountId"], data['subscription']]] }
        data = namespaces.each_with_object([]) do |namespace, acc|
          next unless eligible_namespaces.include?(namespace.id)

          acc << {
            namespace: namespace,
            account_id: eligible_namespaces[namespace.id][0],
            active_subscription: eligible_namespaces[namespace.id][1]
          }
        end

        success(data)
      else
        error('Failed to fetch namespaces', response.dig(:data, :errors))
      end
    end

    private

    attr_reader :user, :namespaces, :plan_id, :any_self_service_plan

    def success(payload)
      ServiceResponse.success(payload: payload)
    end

    def error(message, payload = nil)
      ServiceResponse.error(message: message, payload: payload)
    end

    def missing_user_error
      message = 'User cannot be nil'
      Gitlab::ErrorTracking.track_and_raise_for_dev_exception(ArgumentError.new(message))

      error(message)
    end

    def missing_plan_error
      message = 'plan_id and any_self_service_plan cannot both be nil'
      Gitlab::ErrorTracking.track_and_raise_for_dev_exception(ArgumentError.new(message))

      error(message)
    end

    def response
      strong_memoize(:response) do
        Gitlab::SubscriptionPortal::Client.filter_purchase_eligible_namespaces(
          user,
          namespaces,
          plan_id: plan_id,
          any_self_service_plan: any_self_service_plan
        )
      end
    end
  end
end
