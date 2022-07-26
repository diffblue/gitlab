# frozen_string_literal: true

module Namespaces
  module FreeUserCap
    class AlertComponent < ViewComponent::Base
      # @param [Namespace or Group] namespace
      # @param [User] user
      # @param [String] content_class
      def initialize(namespace:, user:, content_class:)
        @namespace = namespace
        @user = user
        @content_class = content_class
      end

      private

      USER_REACHED_LIMIT_FREE_PLAN_ALERT = 'user_reached_limit_free_plan_alert'

      attr_reader :namespace, :user, :content_class

      def render?
        return false unless user
        return false if dismissed?
        return false unless Ability.allowed?(user, :owner_access, namespace)

        breached_cap_limit?
      end

      def breached_cap_limit?
        ::Namespaces::FreeUserCap::Standard.new(namespace).reached_limit?
      end

      def variant
        :warning
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
        base_alert_data.merge(dismiss_endpoint: group_callouts_path, group_id: namespace.id)
      end

      def base_alert_data
        {
          track_action: 'render',
          track_label: 'user_limit_banner',
          feature_id: feature_name,
          testid: 'user-over-limit-free-plan-alert'
        }
      end

      def feature_name
        USER_REACHED_LIMIT_FREE_PLAN_ALERT
      end

      def close_button_data
        {
          track_action: 'dismiss_banner',
          track_label: 'user_limit_banner',
          testid: 'user-over-limit-free-plan-dismiss'
        }
      end

      def alert_attributes
        {
          title: _("Looks like you've reached your %{free_limit} member limit for " \
                   "%{strong_start}%{namespace_name}%{strong_end}").html_safe % {
            free_limit: ::Namespaces::FreeUserCap::FREE_USER_LIMIT,
            strong_start: "<strong>".html_safe,
            strong_end: "</strong>".html_safe,
            namespace_name: namespace.name
          },
          body: _("You can't add any more, but you can manage your existing members, for example, " \
                  "by removing inactive members and replacing them with new members. To get more " \
                  "members an owner of the group can start a trial or upgrade to a paid tier."),
          primary_cta: namespace_primary_cta,
          secondary_cta: namespace_secondary_cta
        }
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
                group_billings_path(namespace),
                class: 'btn gl-alert-action btn-default btn-md gl-button',
                data: { track_action: 'click_button',
                        track_label: 'explore_paid_plans',
                        testid: 'user-over-limit-secondary-cta' }
      end

      def link_end
        '</a>'.html_safe
      end

      def container_class
        "container-fluid container-limited gl-pb-2! gl-pt-6! #{content_class}"
      end

      def free_user_limit
        ::Namespaces::FreeUserCap::FREE_USER_LIMIT
      end
    end
  end
end
