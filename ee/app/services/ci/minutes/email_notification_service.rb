# frozen_string_literal: true

module Ci
  module Minutes
    class EmailNotificationService < ::BaseService
      include Gitlab::Utils::StrongMemoize

      def execute
        return unless notification.eligible_for_notifications?

        legacy_notify
        notify
      end

      private

      # We use 2 notification objects for new and legacy tracking side-by-side.
      # We read and write data to each tracking using the respective data but we alert
      # only based on the currently active tracking.
      def notification
        @notification ||= ::Ci::Minutes::Notification.new(project, nil, tracking_strategy: :new)
      end

      def legacy_notification
        @legacy_notification ||= ::Ci::Minutes::Notification.new(project, nil, tracking_strategy: :legacy)
      end

      def notify
        if notification.no_remaining_minutes?
          return if namespace_usage.total_usage_notified?

          namespace_usage.update!(notification_level: current_alert_percentage)

          if ci_minutes_use_notification_level?
            CiMinutesUsageMailer.notify(namespace, recipients).deliver_later
          end
        elsif notification.running_out?
          return if namespace_usage.usage_notified?(current_alert_percentage)

          namespace_usage.update!(notification_level: current_alert_percentage)

          if ci_minutes_use_notification_level?
            CiMinutesUsageMailer.notify_limit(namespace, recipients, current_alert_percentage).deliver_later
          end
        end
      end

      def legacy_notify
        if legacy_notification.no_remaining_minutes?
          return if namespace.last_ci_minutes_notification_at

          namespace.update_columns(last_ci_minutes_notification_at: Time.current)

          unless ci_minutes_use_notification_level?
            CiMinutesUsageMailer.notify(namespace, recipients).deliver_later
          end
        elsif legacy_notification.running_out?
          current_alert_percentage = legacy_notification.stage_percentage

          # exit if we have already sent a notification for the same level
          return if namespace.last_ci_minutes_usage_notification_level == current_alert_percentage

          namespace.update_columns(last_ci_minutes_usage_notification_level: current_alert_percentage)

          unless ci_minutes_use_notification_level?
            CiMinutesUsageMailer.notify_limit(namespace, recipients, current_alert_percentage).deliver_later
          end
        end
      end

      def recipients
        namespace.user_namespace? ? [namespace.owner_email] : namespace.owners_emails
      end

      def namespace
        @namespace ||= project.shared_runners_limit_namespace
      end

      def namespace_usage
        @namespace_usage ||= Ci::Minutes::NamespaceMonthlyUsage
          .find_or_create_current(namespace_id: namespace.id)
      end

      def current_alert_percentage
        notification.stage_percentage
      end

      def ci_minutes_use_notification_level?
        strong_memoize(:ci_minutes_use_notification_level) do
          Feature.enabled?(:ci_minutes_use_notification_level, namespace, default_enabled: :yaml)
        end
      end
    end
  end
end
