# frozen_string_literal: true

# Filter a list of namespaces by their eligibility to purchase a new plan.
#
# - When `plan_id: ID` is supplied the eligibility will be checked for that specific plan ID.
#   This param should be supplied when checking add on pack eligibility.
# - When `any_self_service_plan: Boolean` is supplied, the eligibility to have a new self-service plan
#   (ie Premium/Ultimate) in general is checked.
module GitlabSubscriptions
  class FilterPurchaseEligibleNamespacesService
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
        eligible_ids = response[:data].map { |data| data['id'] }.to_set

        data = namespaces.filter { |namespace| eligible_ids.include?(namespace.id) }

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
