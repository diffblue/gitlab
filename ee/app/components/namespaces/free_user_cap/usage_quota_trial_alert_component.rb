# frozen_string_literal: true

module Namespaces
  module FreeUserCap
    class UsageQuotaTrialAlertComponent < BaseAlertComponent
      private

      USAGE_QUOTA_TRIAL_ALERT = 'usage_quota_trial_alert'

      def breached_cap_limit?
        namespace.trial_active? &&
          ::Namespaces::FreeUserCap::Enforcement.new(namespace).enforce_cap?
      end

      def variant
        :info
      end

      def base_alert_data
        {
          testid: 'usage-quota-trial-alert'
        }
      end

      def close_button_data
        { testid: 'usage-quota-trial-dismiss' }
      end

      def feature_name
        USAGE_QUOTA_TRIAL_ALERT
      end

      def alert_attributes
        {
          title: n_(
            'On %{end_date}, your trial will end and %{namespace_name} will be limited to ' \
            '%{free_user_limit} member',
            'On %{end_date}, your trial will end and %{namespace_name} will be limited to ' \
            '%{free_user_limit} members',
            free_user_limit
          ) % {
            end_date: namespace.trial_ends_on&.strftime('%e, %b, %Y'),
            namespace_name: namespace.name,
            free_user_limit: free_user_limit
          },
          body: _(
            '%{over_limit_message} To get more seats, %{link_start}upgrade to a paid tier%{link_end}.'
          ).html_safe % {
            over_limit_message: over_limit_message,
            link_start: '<a rel="noopener noreferrer" href="%{url}">'.html_safe % {
              url: group_billings_path(namespace)
            },
            link_end: link_end
          }
        }
      end

      def container_class
        content_class
      end

      def over_limit_message
        n_(
          "When your trial ends, you'll move to the Free tier, which has a limit of " \
          '%{free_user_limit} seat. %{free_user_limit} seat will remain active, and ' \
          'members not occupying a seat will have the %{link_start}Over limit status%{link_end} ' \
          'and lose access to this group.',
          "When your trial ends, you'll move to the Free tier, which has a limit of " \
          '%{free_user_limit} seats. %{free_user_limit} seats will remain active, and ' \
          'members not occupying a seat will have the %{link_start}Over limit status%{link_end} ' \
          'and lose access to this group.',
          free_user_limit
        ).html_safe % {
          free_user_limit: free_user_limit,
          link_start: blog_link_start,
          link_end: link_end
        }
      end
    end
  end
end
