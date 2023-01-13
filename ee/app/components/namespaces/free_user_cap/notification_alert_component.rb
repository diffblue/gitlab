# frozen_string_literal: true

module Namespaces
  module FreeUserCap
    class NotificationAlertComponent < BaseAlertComponent
      private

      NOTIFICATION_USER_OVER_LIMIT_FREE_PLAN_ALERT = 'preview_user_over_limit_free_plan_alert'
      READ_ONLY_NAMESPACES_URL = 'https://docs.gitlab.com/ee/user/read_only_namespaces.html'

      def breached_cap_limit?
        Shared.over_notification_limit?(namespace)
      end

      def ignore_dismissal_earlier_than
        Shared::NOTIFICATION_IGNORE_DISMISSAL_EARLIER_THAN
      end

      def feature_name
        NOTIFICATION_USER_OVER_LIMIT_FREE_PLAN_ALERT
      end

      def alert_attributes
        {
          title: _(
            'Your top-level group %{namespace_name} is over the %{free_user_limit} user limit'
          ).html_safe % {
            namespace_name: namespace.name,
            free_user_limit: free_user_limit
          },
          body: n_(
            'GitLab will enforce this limit in the future. If you are over %{free_user_limit} ' \
            'user when enforcement begins, your top-level group, including any ' \
            'subgroups and projects, will be placed in a %{link_start}read-only%{link_end} ' \
            'state. To avoid being placed in a read-only state, reduce your top-level group ' \
            'to %{free_user_limit} user or less or purchase a paid tier.',
            'GitLab will enforce this limit in the future. If you are over %{free_user_limit} ' \
            'users when enforcement begins, your top-level group, including any ' \
            'subgroups and projects, will be placed in a %{link_start}read-only%{link_end} ' \
            'state. To avoid being placed in a read-only state, reduce your top-level group ' \
            'to %{free_user_limit} users or less or purchase a paid tier.',
            free_user_limit
          ).html_safe % {
            free_user_limit: free_user_limit,
            link_start: read_only_namespaces_link_start,
            link_end: link_end
          },
          primary_cta: namespace_primary_cta,
          secondary_cta: namespace_secondary_cta
        }
      end

      def read_only_namespaces_link_start
        "<a href='#{READ_ONLY_NAMESPACES_URL}' target='_blank' rel='noopener noreferrer'>".html_safe
      end
    end
  end
end
