# frozen_string_literal: true

module Namespaces
  module FreeUserCap
    class PreviewAlertComponent < AlertComponent
      private

      PREVIEW_USER_OVER_LIMIT_FREE_PLAN_ALERT = 'preview_user_over_limit_free_plan_alert'
      IGNORE_DISMISSAL_EARLIER_THAN = 14.days.ago
      BLOG_URL = 'https://about.gitlab.com/blog/2022/03/24/efficient-free-tier'

      def breached_cap_limit?
        ::Namespaces::FreeUserCap::Preview.new(namespace).over_limit?
      end

      def variant
        :info
      end

      def ignore_dismissal_earlier_than
        IGNORE_DISMISSAL_EARLIER_THAN
      end

      def feature_name
        PREVIEW_USER_OVER_LIMIT_FREE_PLAN_ALERT
      end

      def alert_attributes
        {
          title: n_(
            'From October 19, 2022, free groups will be limited to %d member',
            'From October 19, 2022, free groups will be limited to %d members',
            free_user_limit
          ) % free_user_limit,
          body: _(
            '%{over_limit_message} To get more members, an owner of the group can start ' \
            'a trial or upgrade to a paid tier.'
          ).html_safe % { over_limit_message: over_limit_message },
          primary_cta: namespace_primary_cta,
          secondary_cta: namespace_secondary_cta
        }
      end

      def over_limit_message
        n_(
          'Your group, %{strong_start}%{namespace_name}%{strong_end} has more than %{free_user_limit} ' \
          'member. From October 19, 2022, the %{free_user_limit} most recently active member will remain ' \
          'active, and the remaining members will have the %{link_start}Over limit status%{link_end} and ' \
          'lose access to the group. You can go to the Usage Quotas page to manage which %{free_user_limit} ' \
          'member will remain in your group.',
          'Your group, %{strong_start}%{namespace_name}%{strong_end} has more than %{free_user_limit} ' \
          'members. From October 19, 2022, the %{free_user_limit} most recently active members will remain ' \
          'active, and the remaining members will have the %{link_start}Over limit status%{link_end} and ' \
          'lose access to the group. You can go to the Usage Quotas page to manage which %{free_user_limit} ' \
          'members will remain in your group.',
          free_user_limit
        ).html_safe % {
          strong_start: strong_start,
          strong_end: strong_end,
          namespace_name: namespace.name,
          free_user_limit: free_user_limit,
          link_start: over_limit_link_start,
          link_end: link_end
        }
      end

      def strong_start
        "<strong>".html_safe
      end

      def strong_end
        "</strong>".html_safe
      end

      def over_limit_link_start
        '<a href="%{url}" target="_blank" rel="noopener noreferrer">'.html_safe % { url: BLOG_URL }
      end
    end
  end
end
