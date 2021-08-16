# frozen_string_literal: true

module EE
  module SubscribableBannerHelper
    extend ::Gitlab::Utils::Override

    def gitlab_subscription_or_license
      return decorated_subscription if display_subscription_banner?

      License.current if display_license_banner?
    end

    def gitlab_subscription_message_or_license_message
      return subscription_message if display_subscription_banner?

      license_message if display_license_banner?
    end

    override :display_subscription_banner!
    def display_subscription_banner!
      @display_subscription_banner = true
    end

    def renew_subscription_path
      return plan_renew_url(current_namespace) if decorated_subscription

      "#{EE::SUBSCRIPTIONS_URL}/subscriptions"
    end

    def upgrade_subscription_path
      "#{EE::SUBSCRIPTIONS_URL}/subscriptions"
    end

    private

    def current_namespace
      @project&.namespace || @group
    end

    def license_message(signed_in: signed_in?, is_admin: current_user&.admin?, license: License.current, force_notification: false)
      ::Gitlab::ExpiringSubscriptionMessage.new(
        subscribable: license,
        signed_in: signed_in,
        is_admin: is_admin,
        force_notification: force_notification
      ).message
    end

    def subscription_message
      entity = @project || @group

      ::Gitlab::ExpiringSubscriptionMessage.new(
        subscribable: decorated_subscription,
        signed_in: signed_in?,
        is_admin: can?(current_user, :owner_access, entity.root_ancestor),
        namespace: current_namespace
      ).message
    end

    def decorated_subscription
      entity = @project || @group
      return unless entity && entity.persisted?

      subscription = entity.closest_gitlab_subscription

      return unless subscription

      ::SubscriptionPresenter.new(subscription)
    end

    def display_license_banner?
      ::Feature.enabled?(:subscribable_license_banner, default_enabled: true)
    end

    def display_subscription_banner?
      @display_subscription_banner && ::Gitlab::CurrentSettings.should_check_namespace_plan?
    end
  end
end
