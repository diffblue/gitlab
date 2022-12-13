# frozen_string_literal: true

module Namespaces
  module FreeUserCap
    module Shared
      # region: constants ----------------------------------------------

      ALERT_CLASS = 'js-user-over-limit-free-plan-alert gl-mb-2 gl-mt-6'
      CONTAINER_CLASSES = 'gl-overflow-auto'
      NOTIFICATION_IGNORE_DISMISSAL_EARLIER_THAN = 3.days.ago

      # region: container class ----------------------------------------

      def self.container_class(content_class)
        "#{CONTAINER_CLASSES} #{content_class}"
      end

      # region: enforcement shared ----------------------------------------

      def self.default_render?(user:, namespace:)
        user && Ability.allowed?(user, :owner_access, namespace)
      end

      def self.free_user_limit
        ::Namespaces::FreeUserCap.dashboard_limit
      end

      def self.close_button_data
        {
          track_action: 'dismiss_banner',
          track_label: 'user_limit_banner',
          testid: 'user-over-limit-free-plan-dismiss'
        }
      end

      def self.enforcement_at_limit?(namespace)
        ::Namespaces::FreeUserCap::Enforcement.new(namespace).at_limit?
      end

      def self.enforcement_over_limit?(namespace)
        ::Namespaces::FreeUserCap::Enforcement.new(namespace).over_limit?
      end

      # region: alert data ---------------------------------------------
      # For now, this needs to be split up into separate functions since
      # there are descendents to the base AlertComponent that override
      # different parts

      def self.base_alert_data(feature_name)
        {
          track_action: 'render',
          track_label: 'user_limit_banner',
          feature_id: feature_name,
          testid: 'user-over-limit-free-plan-alert'
        }
      end

      def self.extra_alert_data(namespace)
        {
          dismiss_endpoint: Rails.application.routes.url_helpers.group_callouts_path,
          group_id: namespace.id
        }
      end

      def self.alert_data(namespace:, feature_name:)
        base_alert_data(feature_name).merge(**extra_alert_data(namespace))
      end

      # region: notification specifics --------------------------------------

      def self.notification_dismissed?(user:, namespace:, feature_name:)
        user.dismissed_callout_for_group?(feature_name: feature_name,
                                          group: namespace,
                                          ignore_dismissal_earlier_than: NOTIFICATION_IGNORE_DISMISSAL_EARLIER_THAN)
      end

      def self.over_notification_limit?(namespace)
        ::Namespaces::FreeUserCap::Notification.new(namespace).over_limit?
      end

      def self.non_owner_render?(user:, namespace:)
        return false unless user
        return false if default_render?(user: user, namespace: namespace)

        Ability.allowed?(user, :read_group, namespace)
      end

      # region: html helpers -------------------------------------------

      def self.strong_start
        '<strong>'.html_safe
      end

      def self.strong_end
        '</strong>'.html_safe
      end
    end
  end
end
