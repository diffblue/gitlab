# frozen_string_literal: true

module GitlabSubscriptions
  class NotifySeatsExceededService
    attr_reader :namespace

    def initialize(namespace)
      @namespace = namespace
    end

    def execute
      return error('Namespace is not a top level group') if namespace.subgroup?
      return error('No subscription found for namespace') if subscription.nil?

      subscription.refresh_seat_attributes!

      return error('No seat overage') unless subscription.seats_owed > 0

      notify_users!

      ServiceResponse.success(message: 'Overage notification sent')
    end

    private

    def subscription
      namespace.gitlab_subscription
    end

    def notify_users!
      Gitlab::SubscriptionPortal::Client.send_seat_overage_notification(
        group: namespace,
        max_seats_used: subscription.max_seats_used
      )
    end

    def error(message)
      ServiceResponse.error(message: message)
    end
  end
end
