# frozen_string_literal: true

module Namespaces
  module FreeUserCap
    class PreviewAlertComponent < BaseAlertComponent
      private

      PREVIEW_USER_OVER_LIMIT_FREE_PLAN_ALERT = 'preview_user_over_limit_free_plan_alert'

      def breached_cap_limit?
        Shared.breached_preview_cap_limit?(namespace)
      end

      def variant
        :info
      end

      def ignore_dismissal_earlier_than
        Shared::PREVIEW_IGNORE_DISMISSAL_EARLIER_THAN
      end

      def feature_name
        PREVIEW_USER_OVER_LIMIT_FREE_PLAN_ALERT
      end

      def alert_attributes
        {
          title: alert_title,
          body: _(
            '%{over_limit_message} To get more members, an owner of the group can start ' \
            'a trial or upgrade to a paid tier.'
          ).html_safe % { over_limit_message: over_limit_message },
          primary_cta: namespace_primary_cta,
          secondary_cta: namespace_secondary_cta
        }
      end

      def alert_title
        Shared.preview_alert_title
      end

      def over_limit_message
        free_user_limit = Shared.free_user_limit

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
          strong_start: Shared.strong_start,
          strong_end: Shared.strong_end,
          namespace_name: namespace.name,
          free_user_limit: free_user_limit,
          link_start: blog_link_start,
          link_end: link_end
        }
      end
    end
  end
end
