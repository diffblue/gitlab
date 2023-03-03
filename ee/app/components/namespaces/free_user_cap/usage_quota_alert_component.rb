# frozen_string_literal: true

module Namespaces
  module FreeUserCap
    class UsageQuotaAlertComponent < BaseAlertComponent
      private

      FREE_GROUP_LIMITED_ALERT = 'free_group_limited_alert'

      def breached_cap_limit?
        return false unless subscription_expired? || expired_trial?

        ::Namespaces::FreeUserCap::Enforcement.new(namespace).over_limit?
      end

      def base_alert_data
        {
          track_action: 'render',
          track_property: 'free_group_limited_usage_quota_banner',
          testid: 'free-group-limited-alert'
        }
      end

      def close_button_data
        {
          track_action: 'dismiss_banner',
          track_property: 'free_group_limited_usage_quota_banner',
          testid: 'free-group-limited-dismiss'
        }
      end

      def feature_name
        FREE_GROUP_LIMITED_ALERT
      end

      def alert_attributes
        {
          title: n_(
            'Your free group is now limited to %d member',
            'Your free group is now limited to %d members',
            free_user_limit
          ) % free_user_limit,
          body: s_(
            'Billing|Your group recently changed to use the Free plan. %{over_limit_message} You can free up ' \
            'space for new members by removing those who no longer need access or toggling them to over-limit. ' \
            'To get an unlimited number of members, you can %{link_start}upgrade%{link_end} to a paid tier.'
          ).html_safe % {
            over_limit_message: over_limit_message,
            link_start: '<a data-track-action="click_link" data-track-label="upgrade" ' \
              'data-track-property="free_group_limited_usage_quota_banner" ' \
              'href="%{url}">'.html_safe % { url: group_billings_path(namespace) },
            link_end: '</a>'.html_safe
          }
        }
      end

      def over_limit_message
        n_(
          'Free groups are limited to %{free_user_limit} member and the remaining members will get ' \
          'a status of over-limit and lose access to the group.',
          'Free groups are limited to %{free_user_limit} members and the remaining members will get ' \
          'a status of over-limit and lose access to the group.',
          free_user_limit
        ).html_safe % { free_user_limit: free_user_limit }
      end

      def container_class
        content_class
      end

      def subscription_expired?
        # sometimes namespaces don't have subscriptions, so we need to protect here
        namespace.gitlab_subscription&.expired?
      end

      def expired_trial?
        namespace.trial_expired?
      end
    end
  end
end
