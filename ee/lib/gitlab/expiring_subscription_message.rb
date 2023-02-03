# frozen_string_literal: true

module Gitlab
  class ExpiringSubscriptionMessage
    GRACE_PERIOD_EXTENSION_DAYS = 30.days

    include Gitlab::Utils::StrongMemoize
    include Gitlab::Routing
    include ActionView::Helpers::TextHelper

    attr_reader :subscribable, :signed_in, :is_admin, :namespace, :force_notification

    delegate :auto_renew, to: :subscribable

    def initialize(subscribable:, signed_in:, is_admin:, namespace: nil, force_notification: false)
      @subscribable = subscribable
      @signed_in = signed_in
      @is_admin = is_admin
      @namespace = namespace
      @force_notification = force_notification
    end

    def message
      return unless notifiable?

      message = []
      message << expiration_blocking_message if expiration_blocking_message.present?

      message.join(' ').html_safe
    end

    def subject
      return unless notifiable?

      license_message_subject&.html_safe
    end

    private

    def license_message_subject
      message = subscribable.expired? ? expired_subject : expiring_subject

      message = content_tag(:strong, message)

      content_tag(:p, message, class: 'mb-2')
    end

    def expired_subject
      if namespace && auto_renew
        _('Something went wrong with your automatic subscription renewal.')
      else
        _('Your subscription expired!')
      end
    end

    def expiring_subject
      _('Your %{plan_name} subscription will expire on %{expires_on}') %
        {
          expires_on: subscribable.expires_at.strftime("%Y-%m-%d"),
          plan_name: plan_name
        }
    end

    def expiration_blocking_message
      return '' unless subscribable.will_block_changes?

      message = subscribable.expired? ? expired_message : expiring_message

      content_tag(:p, message.html_safe)
    end

    def expired_message
      return block_changes_message if show_downgrade_messaging?

      n_(
        'No worries, you can still use all the %{strong}%{plan_name}%{strong_close} features for now. You have %{remaining_days} day to renew your subscription.',
        'No worries, you can still use all the %{strong}%{plan_name}%{strong_close} features for now. You have %{remaining_days} days to renew your subscription.',
        remaining_days
      ) % { plan_name: plan_name, remaining_days: remaining_days, strong: strong, strong_close: strong_close }
    end

    def block_changes_message
      return namespace_block_changes_message if namespace

      _('Please delete your current license if you want to downgrade to the free plan.')
    end

    def namespace_block_changes_message
      if auto_renew
        support_link = '<a href="https://support.gitlab.com">support.gitlab.com</a>'.html_safe

        _('We tried to automatically renew your subscription for %{strong}%{namespace_name}%{strong_close} on %{expires_on} but something went wrong so your subscription was downgraded to the free plan. Don\'t worry, your data is safe. We suggest you check your payment method and get in touch with our support team (%{support_link}). They\'ll gladly help with your subscription renewal.') % { strong: strong, strong_close: strong_close, namespace_name: namespace.name, support_link: support_link, expires_on: subscribable.expires_at.strftime("%Y-%m-%d") }
      else
        pricing_url = 'https://about.gitlab.com/pricing/'
        pricing_link_start = '<a href="%{url}">'.html_safe % { url: pricing_url }
        support_email = '<a href="mailto:support@gitlab.com">support@gitlab.com</a>'.html_safe

        s_('Subscription|Your subscription for %{strong}%{namespace_name}%{strong_close} has expired and you are now on %{pricing_link_start}the GitLab Free tier%{pricing_link_end}. Don\'t worry, your data is safe. Get in touch with our support team (%{support_email}). They\'ll gladly help with your subscription renewal.') % { strong: strong, strong_close: strong_close, support_email: support_email, pricing_link_start: pricing_link_start, pricing_link_end: '</a>'.html_safe, namespace_name: namespace.name }
      end
    end

    def expiring_message
      return namespace_expiring_message if namespace

      _("If you don't renew by %{strong}%{downgrades_on}%{strong_close} your instance will become read-only, and you won't be able to create issues or merge requests. You will also lose access to your paid features and support entitlement. %{learn_more_link}") %
        {
          expires_on: subscribable.expires_at.strftime("%Y-%m-%d"),
          downgrades_on: subscribable.block_changes_at.strftime("%Y-%m-%d"),
          learn_more_url: help_page_path('subscriptions/self_managed/index', anchor: 'renew-your-subscription'), target: '_blank', rel: 'noopener noreferrer',
          learn_more_link: '<a href="%{learn_more_url}">How do I renew my subscription?</a>',
          plan_name: plan_name,
          strong: strong,
          strong_close: strong_close
        }
    end

    def namespace_expiring_message
      message = []

      message << _('Your %{strong}%{plan_name}%{strong_close} subscription for %{strong}%{namespace_name}%{strong_close} will expire on %{strong}%{expires_on}%{strong_close}.') % { expires_on: subscribable.expires_at.strftime("%Y-%m-%d"), plan_name: plan_name, strong: strong, strong_close: strong_close, namespace_name: namespace.name }

      message << expiring_features_message

      message.join(' ')
    end

    def expiring_features_message
      _("If you do not renew by %{strong}%{downgrades_on}%{strong_close}, you can't use merge approvals, %{end_message}") %
        {
          downgrades_on: subscribable.block_changes_at.strftime("%Y-%m-%d"),
          end_message: end_message,
          strong: strong,
          strong_close: strong_close
        }
    end

    def end_message
      case plan_name
      when 'Gold', 'Ultimate'
        "epics, security risk mitigation, or any other paid features."
      when 'Premium', 'Silver'
        "epics, or any other paid features."
      else
        "code quality, or any other paid features."
      end
    end

    def notifiable?
      signed_in && with_enabled_notifications? && require_notification?
    end

    def with_enabled_notifications?
      subscribable && ((is_admin && subscribable.notify_admins?) || subscribable.notify_users?)
    end

    def subscription_future_renewal?
      return self_managed_subscription_future_renewal? if self_managed?

      return if namespace.nil? || !namespace.root_ancestor.gitlab_subscription.present?

      ::GitlabSubscriptions::CheckFutureRenewalService.new(namespace: namespace).execute
    end

    def self_managed_subscription_future_renewal?
      ::Gitlab::CurrentSettings.current_application_settings.future_subscriptions.present?
    end

    def require_notification?
      return false if expiring_auto_renew? || ::License.future_dated.present?
      return true if force_notification && subscribable.block_changes?

      auto_renew_choice_exists? && expired_subscribable_within_notification_window? && !subscription_future_renewal?
    end

    def auto_renew_choice_exists?
      !auto_renew.nil?
    end

    def expiring_auto_renew?
      !!auto_renew && !subscribable.expired?
    end

    def expired_subscribable_within_notification_window?
      return true unless subscribable.expired?

      (subscribable.expires_at + GRACE_PERIOD_EXTENSION_DAYS) > Date.today
    end

    def plan_name
      @plan_name ||= subscribable.plan.titleize
    end

    def plan_downgraded?
      plan_name.downcase == ::Plan::FREE
    end

    def show_downgrade_messaging?
      if self_managed?
        subscribable.block_changes?
      else
        subscribable.block_changes? && plan_downgraded?
      end
    end

    def strong
      '<strong>'.html_safe
    end

    def strong_close
      '</strong>'.html_safe
    end

    def self_managed?
      subscribable.is_a?(::License)
    end

    def remaining_days
      strong_memoize(:remaining_days) do
        days = if subscribable.expired?
                 (subscribable.block_changes_at - Date.today).to_i
               else
                 (subscribable.expires_at - Date.today).to_i
               end

        days < 0 ? 0 : days
      end
    end
  end
end

Gitlab::ExpiringSubscriptionMessage.prepend_mod
