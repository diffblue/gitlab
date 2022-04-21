# frozen_string_literal: true

# This sends an email notification to the namespace owners when a new notification
# threshold is hit. We do nothing if we have already sent the notification for the
# current threshold.
module Ci
  module Minutes
    class EmailNotificationService < ::BaseService
      def execute
        return unless notification.eligible_for_notifications?

        # We support 2 different messaging based on whether the
        # namespace is running out of minutes or has already used
        # up all the minutes.
        if notification.no_remaining_minutes?
          notify_minutes_used_up
        elsif notification.running_out?
          notify_minutes_running_out
        end
      end

      private

      def notification
        @notification ||= ::Ci::Minutes::Notification.new(project, nil)
      end

      def notify_minutes_used_up
        return if namespace_usage.total_usage_notified?

        namespace_usage.update!(notification_level: current_alert_percentage)

        CiMinutesUsageMailer.notify(namespace, recipients).deliver_later
      end

      def notify_minutes_running_out
        return if namespace_usage.usage_notified?(current_alert_percentage)

        namespace_usage.update!(notification_level: current_alert_percentage)

        CiMinutesUsageMailer.notify_limit(namespace, recipients, current_alert_percentage).deliver_later
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
    end
  end
end
