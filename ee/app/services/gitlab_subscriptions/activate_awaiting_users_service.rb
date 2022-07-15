# frozen_string_literal: true

module GitlabSubscriptions
  class ActivateAwaitingUsersService
    def initialize(gitlab_subscription:, previous_plan_id:)
      @gitlab_subscription = gitlab_subscription
      @previous_plan_id = previous_plan_id
    end

    def execute
      return unless previous_plan_id
      return unless namespace.group_namespace?
      return unless ::Namespaces::FreeUserCap::Standard.new(namespace).feature_enabled?
      return unless upgrade_from_free_to_paid?

      activate
    end

    private

    attr_reader :gitlab_subscription, :previous_plan_id

    def namespace
      @namespace ||= gitlab_subscription.namespace
    end

    def upgrade_from_free_to_paid?
      !Plan.find(previous_plan_id).paid? && Plan.find(gitlab_subscription.hosted_plan_id).paid?
    end

    def activate
      awaiting_user_ids = namespace.awaiting_user_ids
      return if awaiting_user_ids.empty?
      return if awaiting_user_ids.count > gitlab_subscription.seats_remaining

      ::Members::ActivateService
        .for_users(namespace, users: awaiting_user_ids)
        .execute(current_user: User.automation_bot, skip_authorization: true)
    end
  end
end
