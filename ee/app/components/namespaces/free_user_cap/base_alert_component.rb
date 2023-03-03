# frozen_string_literal: true

module Namespaces
  module FreeUserCap
    class BaseAlertComponent < ViewComponent::Base
      # @param [Namespace or Group] namespace
      # @param [User] user
      # @param [String] content_class
      def initialize(namespace:, user:, content_class:)
        @namespace = namespace
        @user = user
        @content_class = content_class
      end

      private

      BLOG_URL = 'https://about.gitlab.com/blog/2022/03/24/efficient-free-tier'

      attr_reader :namespace, :user, :content_class

      def render?
        return false unless Shared.default_render?(user: user, namespace: namespace)
        return false if dismissed?

        breached_cap_limit?
      end

      def breached_cap_limit?
        Shared.enforcement_over_limit?(namespace)
      end

      def variant
        :warning
      end

      def dismissible
        true
      end

      def dismissed?
        user.dismissed_callout_for_group?(feature_name: feature_name,
                                          group: namespace,
                                          ignore_dismissal_earlier_than: ignore_dismissal_earlier_than)
      end

      def ignore_dismissal_earlier_than
        nil
      end

      def alert_data
        return base_alert_data unless dismissible

        base_alert_data.merge(Shared.extra_alert_data(namespace, feature_name))
      end

      def base_alert_data
        Shared.base_alert_data
      end

      def close_button_data
        Shared.close_button_data
      end

      def namespace_primary_cta
        link_to _('Manage members'),
                group_usage_quotas_path(namespace),
                class: 'btn gl-alert-action btn-info btn-md gl-button',
                data: {
                  track_action: 'click_button',
                  track_label: 'manage_members',
                  testid: 'user-over-limit-primary-cta'
                }
      end

      def namespace_secondary_cta
        link_to _('Explore paid plans'),
                group_billings_path(namespace, source: 'user-limit-alert-enforcement'),
                class: 'btn gl-alert-action btn-default btn-md gl-button',
                data: { track_action: 'click_button',
                        track_label: 'explore_paid_plans',
                        testid: 'user-over-limit-secondary-cta' }
      end

      def link_end
        '</a>'.html_safe
      end

      def container_class
        Shared.container_class(content_class)
      end

      def free_user_limit
        Shared.free_user_limit
      end

      def blog_link_start
        "<a href='#{BLOG_URL}' target='_blank' rel='noopener noreferrer'>".html_safe
      end
    end
  end
end
