# frozen_string_literal: true

module Ci
  module Minutes
    class EmailNotificationService < ::BaseService
      def execute
        return unless notification.eligible_for_notifications?

        notify
      end

      private

      def notification
        @notification ||= ::Ci::Minutes::Notification.new(project, nil)
      end

      def notify
        if notification.no_remaining_minutes?
          notify_total_usage
        elsif notification.running_out?
          notify_partial_usage
        end
      end

      def notify_total_usage
        # TODO: Enable the FF on the month after this is released.
        # https://gitlab.com/gitlab-org/gitlab/-/issues/339324
        if Feature.enabled?(:ci_minutes_use_notification_level, namespace, default_enabled: :yaml)
          return if namespace_usage.total_usage_notified?
        else
          return if namespace.last_ci_minutes_notification_at
        end

        legacy_track_total_usage
        namespace_usage.update!(notification_level: current_alert_percentage)

        CiMinutesUsageMailer.notify(namespace, recipients).deliver_later
      end

      def notify_partial_usage
        # TODO: Enable the FF on the month after this is released.
        # https://gitlab.com/gitlab-org/gitlab/-/issues/339324
        if Feature.enabled?(:ci_minutes_use_notification_level, namespace, default_enabled: :yaml)
          return if namespace_usage.usage_notified?(current_alert_percentage)
        else
          return if already_notified_running_out
        end

        legacy_track_partial_usage
        namespace_usage.update!(notification_level: current_alert_percentage)

        CiMinutesUsageMailer.notify_limit(namespace, recipients, current_alert_percentage).deliver_later
      end

      def already_notified_running_out
        namespace.last_ci_minutes_usage_notification_level == current_alert_percentage
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

      # TODO: delete this method after full rollout of ci_minutes_use_notification_level Feature Flag
      def legacy_track_total_usage
        namespace.update_columns(last_ci_minutes_notification_at: Time.current)
      end

      # TODO: delete this method after full rollout of ci_minutes_use_notification_level Feature Flag
      def legacy_track_partial_usage
        namespace.update_columns(last_ci_minutes_usage_notification_level: current_alert_percentage)
      end
    end
  end
end
