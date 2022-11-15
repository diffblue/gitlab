# frozen_string_literal: true

module Namespaces
  module FreeUserCap
    module Shared
      # region: constants ----------------------------------------------

      ALERT_CLASS = 'js-user-over-limit-free-plan-alert gl-mb-2 gl-mt-6'
      CONTAINER_CLASSES = 'gl-overflow-auto'
      PREVIEW_IGNORE_DISMISSAL_EARLIER_THAN = 14.days.ago

      # region: container class ----------------------------------------

      def self.container_class(content_class)
        "#{CONTAINER_CLASSES} #{content_class}"
      end

      # region: standard shared ----------------------------------------

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

      def self.breached_standard_cap_limit?(namespace)
        ::Namespaces::FreeUserCap::Standard.new(namespace).over_limit?
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

      # region: preview specifics --------------------------------------

      def self.preview_dismissed?(user:, namespace:, feature_name:)
        user.dismissed_callout_for_group?(feature_name: feature_name,
                                          group: namespace,
                                          ignore_dismissal_earlier_than: PREVIEW_IGNORE_DISMISSAL_EARLIER_THAN)
      end

      def self.breached_preview_cap_limit?(namespace)
        ::Namespaces::FreeUserCap::Preview.new(namespace).over_limit?
      end

      def self.non_owner_render?(user:, namespace:)
        return false unless user
        return false if default_render?(user: user, namespace: namespace)

        Ability.allowed?(user, :read_group, namespace)
      end

      def self.preview_render?(user:, namespace:, feature_name:)
        return false unless default_render?(user: user, namespace: namespace)
        return false if preview_dismissed?(user: user, namespace: namespace, feature_name: feature_name)

        breached_preview_cap_limit?(namespace)
      end

      def self.preview_alert_title(free_user_limit = self.free_user_limit)
        n_(
          'From October 19, 2022, free private groups will be limited to %d member',
          'From October 19, 2022, free private groups will be limited to %d members',
          free_user_limit
        ) % free_user_limit
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
